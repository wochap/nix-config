#!/usr/bin/env bash

AGS_OSD_FIFO="/run/user/$UID/progress_osd"
AGS_OSD_ICON_FIFO="/run/user/$UID/progress_icon_osd"

if [[ "$1" == "--volume" ]]; then
  echo "" > $AGS_OSD_ICON_FIFO
  if [[ "$(pactl get-sink-mute @DEFAULT_SINK@)" == "Mute: yes" ]]; then
    pactl set-sink-mute @DEFAULT_SINK@ toggle
  fi
  pactl set-sink-volume @DEFAULT_SINK@ "$2" && pactl get-sink-volume @DEFAULT_SINK@ | head -n 1 | awk '{print substr($5, 1, length($5)-1)}' | xargs -I {} echo {} >$AGS_OSD_FIFO
elif [[ "$1" == "--volume-toggle" ]]; then
  pactl set-sink-mute @DEFAULT_SINK@ toggle
  if [[ "$(pactl get-sink-mute @DEFAULT_SINK@)" == "Mute: yes" ]]; then
    echo "" > $AGS_OSD_ICON_FIFO
    pactl get-sink-volume @DEFAULT_SINK@ | head -n 1 | awk '{print substr($5, 1, length($5)-1)}' >$AGS_OSD_FIFO
    echo -1 >$AGS_OSD_FIFO
  else
    echo "" > $AGS_OSD_ICON_FIFO
    pactl get-sink-volume @DEFAULT_SINK@ | head -n 1 | awk '{print substr($5, 1, length($5)-1)}' >$AGS_OSD_FIFO
  fi
elif [[ "$1" == "--backlight" ]]; then
  echo "" > $AGS_OSD_ICON_FIFO
  backlight "$2" | grep "Current brightness" | awk '{ sub(/\(/, "", $4); print $4 }' | cut -d "%" -f1 >$AGS_OSD_FIFO
elif [[ "$1" == "--kbd-backlight" ]]; then
  echo "" > $AGS_OSD_ICON_FIFO
  kbd-backlight "$2" | grep "Current brightness" | awk '{ sub(/\(/, "", $4); print $4 }' | cut -d "%" -f1 >$AGS_OSD_FIFO
else
  echo -e "Available Options : --volume --volume-toggle --backlight --kbd-backlight"
fi

exit 0
