#!/usr/bin/env bash

set -euo pipefail

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
  --steps=STEPS       Inference steps 1-100 (default: 5)
  --debug             Run in foreground and print every Supertonic input
  --pause             Pause generation and playback
  --resume            Resume paused generation and playback
  --toggle-pause      Toggle between paused and playing; otherwise do nothing
  --stop              Stop any currently playing speech
  -h, --help          Show this help message

Playback options are forwarded to supertonic-speak.

Examples:
  ${0##*/}
  ${0##*/} primary --speed=1.5
  ${0##*/} --format=raw --voice=M2
  ${0##*/} --pause
  ${0##*/} --resume
  ${0##*/} --toggle-pause
  ${0##*/} --stop
EOF
  exit "${1:-2}"
}

selection="clipboard"
selection_set="no"
requested_format="auto"
declare -a speak_args=()

for arg in "$@"; do
  case $arg in
  clipboard | primary)
    if [[ $selection_set == "yes" ]]; then
      printf 'Error: selection already set to "%s"\n' "$selection" >&2
      usage
    fi
    selection=$arg
    selection_set="yes"
    ;;
  --format=*)
    requested_format=${arg#*=}
    ;;
  -h | --help)
    usage 0
    ;;
  *) speak_args+=("$arg") ;;
  esac
done

case $requested_format in
auto | raw | markdown | html) ;;
*)
  printf 'Error: Invalid format "%s"\n' "$requested_format" >&2
  usage
  ;;
esac

# Playback controls do not need clipboard access.
if [[ ${#speak_args[@]} -eq 1 ]]; then
  case ${speak_args[0]} in
  --stop | --pause | --resume | --toggle-pause)
    exec supertonic-speak "${speak_args[@]}"
    ;;
  esac
fi

declare -a selection_args=()
if [[ $selection == "primary" ]]; then
  selection_args+=(--primary)
fi

if ! mime_types=$(wl-paste "${selection_args[@]}" --list-types 2>/dev/null); then
  notify-send --app-name="supertonic-clipboard" --hint=int:transient:1 \
    "Nothing to speak" "The $selection does not contain text"
  exit 1
fi

format=$requested_format
mime_type=""
if [[ $format == "auto" || $format == "html" ]]; then
  mime_type=$(printf '%s\n' "$mime_types" | awk '/^text\/html(;|$)/ { print; exit }')
  if [[ $format == "auto" && -n $mime_type ]]; then
    format="html"
  fi
fi

if [[ $format == "auto" ]]; then
  mime_type=$(printf '%s\n' "$mime_types" | awk '/^text\/(x-)?markdown(;|$)/ { print; exit }')
  # GFM leaves ordinary prose intact while stripping readable Markdown.
  format="markdown"
fi

if [[ -n $mime_type && ( $format == "html" || $requested_format == "auto" ) ]]; then
  text=$(wl-paste "${selection_args[@]}" --no-newline --type "$mime_type")
else
  text=$(wl-paste "${selection_args[@]}" --no-newline --type text)
fi

exec supertonic-speak "$text" --format="$format" "${speak_args[@]}"
