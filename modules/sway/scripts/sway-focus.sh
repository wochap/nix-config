#!/usr/bin/env bash
# https://gitlab.com/wef/dotfiles/-/blob/master/bin/sway-focus

TIME_STAMP="20211102.175153"

# Copyright (C) 2020-2021 Bob Hepple <bob dot hepple at gmail dot com>

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or (at
# your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

PROG=$(basename $0)
toggle=""
origin=""
TEMP=$(getopt --options sth --longoptions toggle-scratchpad,send-to-origin,help -- "$@") || exit 1
eval set -- "$TEMP"

for i in "$@"; do
  case "$i" in
  -h | --help)
    echo "Usage: $PROG [-t|--toggle-scratchpad app_id|class [runstring]"
    echo
    echo "Give focus to a program based on app_id or class (Xwayland)"
    echo "-t|--toggle-scratchpad    send the program to/from scratchpad"
    echo "-s|--send-to-origin       also send to 0,0"
    exit 0
    ;;
  -t | --tog*)
    toggle="set"
    shift
    ;;
  -s | --send-to-origin)
    origin="set"
    shift
    ;;
  esac
done

shift
target="$1"
runstring="$2"

echo "$PROG: target='$target' runstring='$runstring'" >&2

[[ "$toggle" ]] && {
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
  exit 0
}

swaymsg "[app_id=$target] focus" 2>/dev/null || {
  # could be Xwayland app:
  swaymsg "[class=$target] focus" 2>/dev/null || {
    [[ "$runstring" ]] && {
      # not running yet?
      set -- $runstring
      pkill -0 $1 || xcheck exec $runstring || exit 0
    }
  }
}

# Local Variables:
# mode: shell-script
# time-stamp-pattern: "4/TIME_STAMP=\"%:y%02m%02d.%02H%02M%02S\""
# eval: (add-hook 'before-save-hook 'time-stamp)
# End:
