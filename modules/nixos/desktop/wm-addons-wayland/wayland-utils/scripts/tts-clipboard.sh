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

speak() {
  local selection=$1
  local text
  local audio_file

  if [[ $selection == "primary" ]]; then
    text=$(wl-paste --primary --no-newline --type text 2>/dev/null) || {
      notify "Nothing to speak" "The primary selection does not contain text"
      exit 1
    }
  else
    text=$(wl-paste --no-newline --type text 2>/dev/null) || {
      notify "Nothing to speak" "The clipboard does not contain text"
      exit 1
    }
  fi

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
    "$0" --worker "$selection"
}

case ${1:-clipboard} in
  clipboard)
    toggle clipboard
    ;;
  primary)
    toggle primary
    ;;
  stop)
    systemctl --user stop "$playback_unit"
    ;;
  --worker)
    speak "${2:-clipboard}"
    ;;
  *)
    printf 'Usage: %s [clipboard|primary|stop]\n' "${0##*/}" >&2
    exit 2
    ;;
esac
