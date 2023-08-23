#!/usr/bin/env bash

WOBSOCK="/run/user/501/wob.sock"

if [[ "$1" == "--volume" ]]; then
  pactl set-sink-volume @DEFAULT_SINK@ "$2" && pactl get-sink-volume @DEFAULT_SINK@ | head -n 1 | awk '{print substr($5, 1, length($5)-1)}' >$WOBSOCK
elif [[ "$1" == "--volume-toggle" ]]; then
  pactl set-sink-mute @DEFAULT_SINK@ toggle
  if [[ "$(pactl get-sink-mute @DEFAULT_SINK@)" == "Mute: yes" ]]; then
    echo 0 >$WOBSOCK
  else
    pactl get-sink-volume @DEFAULT_SINK@ | head -n 1 | awk '{print substr($5, 1, length($5)-1)}' >$WOBSOCK
  fi
elif [[ "$1" == "--backlight" ]]; then
  /etc/scripts/backlight.sh "$2" | grep "Current brightness" | awk '{ sub(/\(/, "", $4); print $4 }' | cut -d "%" -f1 >$WOBSOCK
elif [[ "$1" == "--kbd-backlight" ]]; then
  /etc/scripts/kbd-backlight.sh "$2" | grep "Current brightness" | awk '{ sub(/\(/, "", $4); print $4 }' | cut -d "%" -f1 >$WOBSOCK
else
  echo -e "Available Options : --volume --volume-toggle --backlight --kbd-backlight"
fi

exit 0
