#!/usr/bin/env bash

ENABLED=
DISABLED=
FILE="$HOME/tmp/offlinemsmtp-sendmail"

reload_waybar() {
  pkill -SIGRTMIN+8 waybar
}

toggle() {
  notify="notify-send --urgency=low --replace-id=694 offlinemsmtp"

  if test -f "$FILE"; then
    rm "$FILE"
    $notify "Offlinemsmtp is disabled"
    reload_waybar
  else
    touch "$FILE"
    $notify "Offlinemsmtp is enabled"
    reload_waybar
  fi
}

read() {
  if test -f "$FILE"; then
    printf '{ "text": "%s", "class": "enabled" }' "$ENABLED"
  else
    printf '{ "text": "%s", "class": "disabled" }' "$DISABLED"
  fi
}

if [[ "$1" == "--toggle" ]]; then
  toggle
elif [[ "$1" == "--read" ]]; then
  read
else
  echo -e "Available Options : --toggle --read"
fi
