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

    if (( SECONDS - started_at >= 600 )); then
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
    raw)
      ;;
  esac
}

speak() {
  local selection=$1
  local format=$2
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

  if (( ${#text} > 20000 )); then
    notify "Text is too long" "Clipboard TTS is limited to 20,000 characters"
    exit 1
  fi

  ensure_supertonic

  audio_file=$(mktemp --tmpdir="${XDG_RUNTIME_DIR:-/tmp}" tts-clipboard.XXXXXX.wav)
  trap 'rm -f "$audio_file"' EXIT

  notify "Generating speech" "${#text} characters"

  jq -cn \
    --arg input "$text" \
    '{model: "supertonic-3", input: $input, voice: "M1", response_format: "wav"}' \
    | curl \
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

  if systemctl --user is-active --quiet "$playback_unit"; then
    systemctl --user stop "$playback_unit"
    notify "Speech stopped"
    exit 0
  fi

  systemd-run \
    --user \
    --unit="${playback_unit%.service}" \
    --collect \
    --quiet \
    --service-type=exec \
    --setenv=PATH="$PATH" \
    "$0" --worker "$selection" "$format"
}

if [[ ${1:-} == "--worker" ]]; then
  speak "${2:-clipboard}" "${3:-auto}"
  exit
fi

selection=clipboard
format=auto

for argument in "$@"; do
  case $argument in
    clipboard | primary)
      selection=$argument
      ;;
    auto | raw | markdown | html)
      format=$argument
      ;;
    stop)
      systemctl --user stop "$playback_unit"
      exit
      ;;
    *)
      printf 'Usage: %s [clipboard|primary] [auto|raw|markdown|html|stop]\n' "${0##*/}" >&2
      exit 2
      ;;
  esac
done

toggle "$selection" "$format"
