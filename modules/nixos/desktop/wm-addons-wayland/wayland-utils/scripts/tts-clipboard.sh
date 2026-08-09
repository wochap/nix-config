#!/usr/bin/env bash

set -euo pipefail

readonly playback_unit="tts-clipboard-player.service"

notify() {
  notify-send \
    --app-name="TTS" \
    --hint=int:transient:1 \
    "$1" \
    "${2:-}"
}

ensure_supertonic() {
  local started_at=$SECONDS

  if curl --fail --silent --max-time 1 http://127.0.0.1:7788/v1/health >/dev/null; then
    return
  fi

  notify "Starting Supertonic" "The first start may download about 400 MB"

  if ! systemctl --user start supertonic.service; then
    notify "Supertonic failed to start" "Check the user service journal"
    return 1
  fi

  until curl --fail --silent --max-time 1 http://127.0.0.1:7788/v1/health >/dev/null; do
    if systemctl --user is-failed --quiet supertonic.service; then
      notify "Supertonic failed to start" "Check the user service journal"
      return 1
    fi

    if ((SECONDS - started_at >= 600)); then
      notify "Supertonic startup timed out" "Check the user service journal"
      return 1
    fi

    sleep 0.5
  done
}

read_clipboard() {
  local selection=$1
  local requested_format=$2
  local mime_types
  local mime_type
  local -a selection_args=()

  if [[ $selection == "primary" ]]; then
    selection_args+=(--primary)
  fi

  mime_types=$(wl-paste "${selection_args[@]}" --list-types 2>/dev/null) || return 1
  format=$requested_format

  if [[ $format == "auto" ]]; then
    mime_type=$(printf '%s\n' "$mime_types" | awk '/^text\/html(;|$)/ { print; exit }')
    if [[ -n $mime_type ]]; then
      format=html
      text=$(wl-paste "${selection_args[@]}" --no-newline --type "$mime_type")
      return
    fi

    mime_type=$(printf '%s\n' "$mime_types" | awk '/^text\/(x-)?markdown(;|$)/ { print; exit }')
    if [[ -n $mime_type ]]; then
      format=markdown
      text=$(wl-paste "${selection_args[@]}" --no-newline --type "$mime_type")
      return
    fi

    # Plain text may itself contain Markdown copied from an editor. Pandoc's
    # GFM reader leaves ordinary prose intact while removing readable markup.
    format=markdown
  fi

  if [[ $format == "html" ]]; then
    mime_type=$(printf '%s\n' "$mime_types" | awk '/^text\/html(;|$)/ { print; exit }')
    if [[ -n $mime_type ]]; then
      text=$(wl-paste "${selection_args[@]}" --no-newline --type "$mime_type")
      return
    fi
  fi

  text=$(wl-paste "${selection_args[@]}" --no-newline --type text)
}

normalize_text() {
  case $format in
  html)
    text=$(printf '%s' "$text" | pandoc --from=html --to=plain --wrap=none)
    ;;
  markdown)
    text=$(printf '%s' "$text" | pandoc --from=gfm --to=plain --wrap=none)
    ;;
  raw) ;;
  esac
}

speak() {
  local selection=$1
  local format=$2
  local speed=$3
  local voice=$4
  local text
  local audio_file

  read_clipboard "$selection" "$format" || {
    notify "Nothing to speak" "The $selection does not contain text"
    exit 1
  }

  normalize_text || {
    notify "Could not prepare text" "Pandoc failed to convert the $format input"
    exit 1
  }

  if [[ -z ${text//[[:space:]]/} ]]; then
    notify "Nothing to speak" "The selected text is empty"
    exit 1
  fi

  if ((${#text} > 20000)); then
    notify "Text is too long" "Clipboard TTS is limited to 20,000 characters"
    exit 1
  fi

  ensure_supertonic

  audio_file=$(mktemp --tmpdir="${XDG_RUNTIME_DIR:-/tmp}" tts-clipboard.XXXXXX.wav)
  trap 'rm -f "$audio_file"' EXIT

  notify "Generating speech" "${#text} characters, voice $voice at ${speed}x speed"

  jq -cn \
    --arg input "$text" \
    --arg voice "$voice" \
    --argjson speed "$speed" \
    '{model: "supertonic-3", input: $input, voice: $voice, response_format: "wav", speed: $speed}' |
    curl \
      --fail \
      --show-error \
      --silent \
      --header "content-type: application/json" \
      --data-binary @- \
      --output "$audio_file" \
      http://127.0.0.1:7788/v1/audio/speech

  pw-play "$audio_file"
}

toggle() {
  local selection=$1
  local format=$2
  local speed=$3
  local voice=$4

  if systemctl --user is-active --quiet "$playback_unit"; then
    systemctl --user stop "$playback_unit"
    notify "Speech stopped"
    exit 0
  fi

  # Pass arguments using strict --key=value format to the worker
  systemd-run \
    --user \
    --unit="${playback_unit%.service}" \
    --collect \
    --quiet \
    --service-type=exec \
    --setenv=PATH="$PATH" \
    "$0" --worker --selection="$selection" --format="$format" --speed="$speed" --voice="$voice"
}

usage() {
  cat <<EOF >&2
Usage: ${0##*/} [clipboard|primary] [OPTIONS]

Positional Arguments:
  clipboard           Use the standard clipboard (default)
  primary             Use the primary selection (middle-click)

Options:
  --format=FORMAT     Input format: auto, raw, markdown, html (default: auto)
  --voice=NAME        Voice identifier (default: M1)
  --speed=SPEED       Playback speed 0.7-2.0 (default: 1.0)
  --stop              Stop any currently playing speech
  -h, --help          Show this help message

Examples:
  ${0##*/} primary --format=markdown --speed=1.5
  ${0##*/} --voice=M2 --speed=2.0
  ${0##*/} --stop
EOF
  exit "${1:-2}"
}

# --- Internal Worker Entry Point ---
if [[ ${1:-} == "--worker" ]]; then
  shift
  w_selection="clipboard"
  w_format="auto"
  w_speed="1.0"
  w_voice="M1"

  while (($# > 0)); do
    case $1 in
    --selection=*) w_selection=${1#*=} ;;
    --format=*) w_format=${1#*=} ;;
    --speed=*) w_speed=${1#*=} ;;
    --voice=*) w_voice=${1#*=} ;;
    *)
      echo "Worker: unknown arg: $1" >&2
      exit 2
      ;;
    esac
    shift
  done

  speak "$w_selection" "$w_format" "$w_speed" "$w_voice"
  exit
fi

# --- Main CLI Parsing ---
selection=""
format="auto"
speed="1.0"
voice="M1"

while (($# > 0)); do
  case $1 in
  # Positional: Selection (only allowed if not yet set)
  clipboard | primary)
    if [[ -n $selection ]]; then
      printf 'Error: selection already set to "%s"\n' "$selection" >&2
      usage
    fi
    selection=$1
    ;;

  # Strict Options
  --format=*)
    format=${1#*=}
    ;;
  --voice=*)
    voice=${1#*=}
    ;;
  --speed=*)
    speed=${1#*=}
    ;;
  --stop)
    systemctl --user stop "$playback_unit" 2>/dev/null || true
    notify "Speech stopped"
    exit 0
    ;;
  -h | --help)
    usage 0
    ;;

  # Reject bare --key without =value
  --format | --voice | --speed)
    printf 'Error: %s requires a value. Use %s=VALUE\n' "$1" "$1" >&2
    usage
    ;;

  # Reject anything else
  *)
    printf 'Error: Unknown argument "%s"\n' "$1" >&2
    usage
    ;;
  esac
  shift
done

# Default selection if none provided
selection=${selection:-clipboard}

# Validate format
case $format in
auto | raw | markdown | html) ;;
*)
  printf 'Error: Invalid format "%s"\n' "$format" >&2
  usage
  ;;
esac

# Validate voice
if [[ -z $voice ]]; then
  printf 'Error: --voice cannot be empty\n' >&2
  usage
fi

# Validate speed
if ! [[ $speed =~ ^[0-9]+(\.[0-9]+)?$ ]] ||
  ! awk -v s="$speed" 'BEGIN { exit !(s >= 0.7 && s <= 2.0) }'; then
  printf 'Error: --speed must be a number between 0.7 and 2.0\n' >&2
  usage
fi

toggle "$selection" "$format" "$speed" "$voice"
