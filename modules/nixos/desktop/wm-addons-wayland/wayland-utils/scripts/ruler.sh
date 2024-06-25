#!/usr/bin/env bash

EXPIRE_TIME=5000

# source theme colors
source "$HOME/.config/scripts/theme-colors.sh"

if [[ -n $(pgrep slurp) ]]; then
  # slurp is already running
  exit 0
fi

area=$(slurp -d -b "${background}bf" -c "$primary" -F "Iosevka NF" -w 1 -f "%w:%h")

if [[ -z $area ]]; then
  # slurp canceled
  exit
fi

# copy to clipboard
printf "%s" "$area" | wl-copy --trim-newline --type text/plain

# show notification
notify-send --app-name="Ruler" --icon="accessories-screenshot" --expire-time="$EXPIRE_TIME" --replace-id=690 "width:height" "$area"
