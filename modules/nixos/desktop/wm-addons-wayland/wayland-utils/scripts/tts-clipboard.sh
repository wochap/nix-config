#!/usr/bin/env bash

set -euo pipefail

readonly playback_unit="tts-clipboard-player.service"

notify() {
  notify-send \
    --app-name="tts-clipboard" \
    --hint=int:transient:1 \
    "$1" \
    "${2:-}"
}

ensure_supertonic() {
  if ! curl --fail --silent --max-time 1 http://127.0.0.1:7788/v1/health >/dev/null; then
    notify "Supertonic is not running" "Enable it from the Control Center"
    return 1
  fi
}

read_clipboard() {
  local selection=$1
  local requested_format=$2
  local mime_types
  local mime_type
  local -a selection_args=()

  source_format="plain text"

  if [[ $selection == "primary" ]]; then
    selection_args+=(--primary)
  fi

  mime_types=$(wl-paste "${selection_args[@]}" --list-types 2>/dev/null) || return 1
  format=$requested_format

  if [[ $format == "auto" ]]; then
    mime_type=$(printf '%s\n' "$mime_types" | awk '/^text\/html(;|$)/ { print; exit }')
    if [[ -n $mime_type ]]; then
      format=html
      source_format="HTML"
      text=$(wl-paste "${selection_args[@]}" --no-newline --type "$mime_type")
      return
    fi

    mime_type=$(printf '%s\n' "$mime_types" | awk '/^text\/(x-)?markdown(;|$)/ { print; exit }')
    if [[ -n $mime_type ]]; then
      format=markdown
      source_format="Markdown"
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
      source_format="HTML"
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

  # Rich clipboard content can contain Unicode object replacement characters
  # (U+FFFC) for embedded images or other non-text objects. They are not
  # speakable and can cause the TTS backend to reject the request.
  text=${text//$'\uFFFC'/}

  # Supertonic currently returns HTTP 500 for emoji input. Replace emoji and
  # their sequence helpers (variation selectors, joiners, and keycaps) with
  # spaces before chunking so removing one cannot accidentally join two words.
  text=$(jq -Rrs '
    explode
    | map(
        if . == 8205
          or (. >= 65024 and . <= 65039)
          or . == 8419
          or . == 169 or . == 174
          or . == 8252 or . == 8265
          or . == 8482 or . == 8505
          or (. >= 8592 and . <= 8703)
          or (. >= 8960 and . <= 9215)
          or (. >= 9312 and . <= 9471)
          or (. >= 9632 and . <= 10175)
          or (. >= 10548 and . <= 10549)
          or (. >= 11008 and . <= 11263)
          or . == 12336 or . == 12349
          or . == 12951 or . == 12953
          or (. >= 126976 and . <= 129791)
        then 32
        else .
        end
      )
    | implode
  ' <<<"$text")
}

split_text() {
  # Keep sentence boundaries where practical while limiting the time until the
  # first playable chunk. Long individual sentences are split at word boundaries.
  printf '%s\n' "$text" | awk -v max=400 '
    function flush() {
      if (length(chunk) > 0) {
        print chunk
        chunk = ""
      }
    }

    function add(part, words, count, i, candidate) {
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", part)
      if (length(part) == 0)
        return

      if (length(part) > max) {
        count = split(part, words, /[[:space:]]+/)
        for (i = 1; i <= count; i++) {
          candidate = length(chunk) > 0 ? chunk " " words[i] : words[i]
          if (length(candidate) > max && length(chunk) > 0)
            flush()
          chunk = length(chunk) > 0 ? chunk " " words[i] : words[i]
        }
        return
      }

      candidate = length(chunk) > 0 ? chunk " " part : part
      if (length(candidate) > max)
        flush()
      chunk = length(chunk) > 0 ? chunk " " part : part
    }

    {
      # Pandoc renders headings as short standalone lines. Keep them with the
      # following prose so TTS backends do not receive one-word audio requests.
      if (NF > 0 && length($0) <= 80 && $0 !~ /[.!?][[:space:]]*$/)
        $0 = $0 "."

      remaining = $0
      while (match(remaining, /[^.!?]*[.!?]+([[:space:]]+|$)/)) {
        # The match can start after a non-boundary period in text such as
        # "e.g.", "Lindy.ai", or a period followed by a closing quote. Include
        # that unmatched prefix instead of silently discarding it.
        add(substr(remaining, 1, RSTART + RLENGTH - 1))
        remaining = substr(remaining, RSTART + RLENGTH)
      }
      add(remaining)
    }

    END { flush() }
  '
}

generate_audio() {
  local chunk=$1
  local output=$2
  local voice=$3
  local steps=$4
  local debug=$5

  if [[ $debug == "on" ]]; then
    printf '\n--- Supertonic input (%d characters) ---\n%s\n--- End Supertonic input ---\n' \
      "${#chunk}" "$chunk" >&2
  fi

  # For English-only input, add `lang: "en"` to this object and compare it
  # with Supertonic's automatic language handling.
  jq -cn \
    --arg text "$chunk" \
    --arg voice "$voice" \
    --argjson steps "$steps" \
    '{text: $text, voice: $voice, steps: $steps, speed: 1.0, max_chunk_length: 400, silence_duration: 0.15, response_format: "wav"}' |
    curl \
      --fail \
      --show-error \
      --silent \
      --header "content-type: application/json" \
      --data-binary @- \
      --output "$output" \
      http://127.0.0.1:7788/v1/tts
}

speak() {
  local selection=$1
  local format=$2
  local speed=$3
  local voice=$4
  local chunking=$5
  local steps=$6
  local debug=$7
  local text
  local source_format
  local work_dir
  local generation_pid
  local i
  local -a chunks

  read_clipboard "$selection" "$format" || {
    notify "Nothing to speak" "The $selection does not contain text"
    exit 1
  }

  if [[ $debug == "on" ]]; then
    printf 'Clipboard input: %s; normalization: %s\n' "$source_format" "$format" >&2
  fi

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

  if [[ $chunking == "on" ]]; then
    mapfile -t chunks < <(split_text)
  else
    chunks=("$text")
  fi
  if ((${#chunks[@]} == 0)); then
    notify "Nothing to speak" "The selected text is empty"
    exit 1
  fi

  work_dir=$(mktemp --directory --tmpdir="${XDG_RUNTIME_DIR:-/tmp}" tts-clipboard.XXXXXX)
  trap 'rm -rf "$work_dir"' EXIT

  notify "Generating speech" "${#text} characters in ${#chunks[@]} chunks, voice $voice with ${speed}x playback and $steps steps"

  if ! generate_audio "${chunks[0]}" "$work_dir/0.wav" "$voice" "$steps" "$debug"; then
    notify "Could not generate speech" "Supertonic failed while preparing the first chunk"
    return 1
  fi

  for ((i = 0; i < ${#chunks[@]}; i++)); do
    if ((i + 1 < ${#chunks[@]})); then
      generate_audio "${chunks[i + 1]}" "$work_dir/$((i + 1)).wav" "$voice" "$steps" "$debug" &
      generation_pid=$!
    else
      generation_pid=""
    fi

    mpv \
      --no-config \
      --no-video \
      --no-terminal \
      --really-quiet \
      --audio-pitch-correction=yes \
      --speed="$speed" \
      "$work_dir/$i.wav"

    if [[ -n $generation_pid ]] && ! wait "$generation_pid"; then
      notify "Could not generate speech" "Supertonic failed while preparing the next chunk"
      return 1
    fi
  done
}

toggle() {
  local selection=$1
  local format=$2
  local speed=$3
  local voice=$4
  local chunking=$5
  local steps=$6
  local debug=$7

  if systemctl --user is-active --quiet "$playback_unit"; then
    systemctl --user stop "$playback_unit"
    notify "Speech stopped"
    exit 0
  fi

  if [[ $debug == "on" ]]; then
    speak "$selection" "$format" "$speed" "$voice" "$chunking" "$steps" "$debug"
    return
  fi

  # Pass arguments using strict --key=value format to the worker
  systemd-run \
    --user \
    --unit="${playback_unit%.service}" \
    --collect \
    --quiet \
    --service-type=exec \
    --setenv=PATH="$PATH" \
    "$0" --worker --selection="$selection" --format="$format" --speed="$speed" --voice="$voice" --chunking="$chunking" --steps="$steps"
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
  --chunking=MODE     Pipelined playback: on or off (default: on)
  --steps=STEPS       Inference steps 1-100 (default: 3)
  --debug             Run in foreground and print every Supertonic input
  --stop              Stop any currently playing speech
  -h, --help          Show this help message

Examples:
  ${0##*/} primary --format=markdown --speed=1.5
  ${0##*/} --voice=M2 --speed=2.0 --steps=2
  ${0##*/} --chunking=off --steps=8
  ${0##*/} --debug --chunking=on
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
  w_chunking="on"
  w_steps="3"

  while (($# > 0)); do
    case $1 in
    --selection=*) w_selection=${1#*=} ;;
    --format=*) w_format=${1#*=} ;;
    --speed=*) w_speed=${1#*=} ;;
    --voice=*) w_voice=${1#*=} ;;
    --chunking=*) w_chunking=${1#*=} ;;
    --steps=*) w_steps=${1#*=} ;;
    *)
      echo "Worker: unknown arg: $1" >&2
      exit 2
      ;;
    esac
    shift
  done

  speak "$w_selection" "$w_format" "$w_speed" "$w_voice" "$w_chunking" "$w_steps" "off"
  exit
fi

# --- Main CLI Parsing ---
selection=""
format="auto"
speed="1.0"
voice="M1"
chunking="on"
steps="3"
debug="off"

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
  --chunking=*)
    chunking=${1#*=}
    ;;
  --steps=*)
    steps=${1#*=}
    ;;
  --debug)
    debug="on"
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
  --format | --voice | --speed | --chunking | --steps)
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

# Validate chunking
case $chunking in
on | off) ;;
*)
  printf 'Error: --chunking must be either on or off\n' >&2
  usage
  ;;
esac

# Validate inference steps against the native Supertonic API range
if ! [[ $steps =~ ^[0-9]+$ ]] || ((10#$steps < 1 || 10#$steps > 100)); then
  printf 'Error: --steps must be an integer between 1 and 100\n' >&2
  usage
fi
steps=$((10#$steps))

toggle "$selection" "$format" "$speed" "$voice" "$chunking" "$steps" "$debug"
