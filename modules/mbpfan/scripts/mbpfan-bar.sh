#!/usr/bin/env bash

ICON=󰈐

toggle() {
  exec /etc/scripts/tofi-mbpfan.sh &
}

read() {
  CURRENT_SPEED=$(cat /sys/devices/platform/applesmc.768/fan*_output | head -n1)
  echo "$ICON  $CURRENT_SPEED"
}

if [[ "$1" == "--toggle" ]]; then
  toggle
elif [[ "$1" == "--read" ]]; then
  read
else
  echo -e "Available Options : --toggle --read"
fi

