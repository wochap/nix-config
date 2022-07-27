#!/usr/bin/env bash
# https://gitlab.com/wef/dotfiles/-/blob/master/bin/sway-focus

PROG=$(basename $0)
TEMP=$(getopt --options sth --longoptions toggle-scratchpad,send-to-origin,help -- "$@") || exit 1
eval set -- "$TEMP"
shift
target="$1"
runstring="$2"
echo "$PROG: target='$target' runstring='$runstring'" >&2

program_data=$(swaymsg -t get_tree | jq ".. | select(.type?) | select(.app_id==\"$target\" or .window_properties.class==\"$target\")")
if [[ "$program_data" ]]; then
  id=$(echo "$program_data" | jq ".id" | head -n 1)
  visible=$(echo "$program_data" | jq ".visible" | head -n 1)
  if [[ "$visible" == "false" ]]; then
    swaymsg "[con_id=$id] move window to workspace current" &>/dev/null
    swaymsg "[con_id=$id] focus" &>/dev/null
    if [[ "$origin" ]]; then
      swaymsg "[con_id=$id] move position 0 0"
    fi
  else
    swaymsg "[con_id=$id] move window to scratchpad" &>/dev/null
  fi
else
  if [[ "$runstring" ]]; then
    swaymsg exec "$runstring"
  fi
fi
