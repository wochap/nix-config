#!/usr/bin/env bash

AGSOSDFIFO="/run/user/$UID/ags_osd"

if [[ "$1" == "--volume" ]]; then
  pactl set-sink-volume @DEFAULT_SINK@ "$2" && pactl get-sink-volume @DEFAULT_SINK@ | head -n 1 | awk '{print substr($5, 1, length($5)-1)}' | xargs -I {} echo {} >$AGSOSDFIFO
elif [[ "$1" == "--volume-toggle" ]]; then
  pactl set-sink-mute @DEFAULT_SINK@ toggle
  if [[ "$(pactl get-sink-mute @DEFAULT_SINK@)" == "Mute: yes" ]]; then
    pactl get-sink-volume @DEFAULT_SINK@ | head -n 1 | awk '{print substr($5, 1, length($5)-1)}' >$AGSOSDFIFO
    echo -1 >$AGSOSDFIFO
  else
    pactl get-sink-volume @DEFAULT_SINK@ | head -n 1 | awk '{print substr($5, 1, length($5)-1)}' >$AGSOSDFIFO
  fi
elif [[ "$1" == "--backlight" ]]; then
  backlight "$2" | grep "Current brightness" | awk '{ sub(/\(/, "", $4); print $4 }' | cut -d "%" -f1 >$AGSOSDFIFO
elif [[ "$1" == "--kbd-backlight" ]]; then
  kbd-backlight "$2" | grep "Current brightness" | awk '{ sub(/\(/, "", $4); print $4 }' | cut -d "%" -f1 >$AGSOSDFIFO
else
  echo -e "Available Options : --volume --volume-toggle --backlight --kbd-backlight"
fi

exit 0
