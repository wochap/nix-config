#!/usr/bin/env bash

PROG=$(basename $0)
toggle=""
TEMP=$(getopt --options sth --longoptions toggle-scratchpad,help -- "$@") || exit 1
eval set -- "$TEMP"

for i in "$@"; do
  case "$i" in
  -h | --help)
    echo "Usage: $PROG [-t|--toggle-scratchpad app|title [runstring]"
    echo
    echo "Give focus to a program based on app or title (yabai)"
    echo "-t|--toggle-scratchpad    send the program to/from scratchpad"
    exit 0
    ;;
  -t | --tog*)
    toggle="set"
    shift
    ;;
  esac
done

shift
target="$1"
runstring="$2"

echo "$PROG: target='$target' runstring='$runstring'" >&2

[[ "$toggle" ]] && {
  program_data=$(yabai -m query --windows | jq ".[] | select(.app==\"$target\" or .title==\"$target\")")
  if [[ "$program_data" ]]; then
    id=$(echo "$program_data" | jq ".id" | head -n 1)
    visible=$(echo "$program_data" | jq ".\"is-visible\"" | head -n 1)
    if [[ "$visible" == "false" ]]; then
      # yabai -m window $id --display mouse &>/dev/null
      yabai -m window $id --space mouse
      yabai -m window $id --focus &>/dev/null
    else
      yabai -m window $id --minimize &>/dev/null
    fi
  else
    if [[ "$runstring" ]]; then
      exec sh -c "$runstring" > /dev/null 2>&1 &
    fi
  fi
  exit 0
}

program_data=$(yabai -m query --windows | jq ".[] | select(.app==\"$target\" or .title==\"$target\")")
if [[ "$program_data" ]]; then
  id=$(echo "$program_data" | jq ".id" | head -n 1)
  yabai -m window $id --focus &>/dev/null
else
  if [[ "$runstring" ]]; then
    exec "$runstring"
  fi
fi
