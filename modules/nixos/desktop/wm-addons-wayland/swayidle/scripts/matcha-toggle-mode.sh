#!/usr/bin/env bash

ENABLED=
DISABLED=
FILE="$HOME/tmp/matcha"

toggle() {
  notify="notify-send --urgency=low --replace-id=695 matcha"

  status=$(MATCHA_WAYBAR_OFF=false MATCHA_WAYBAR_ON=true matcha --toggle --bar=waybar | head -n 1)
  case $status in
  true)
    if test ! -f "$FILE"; then
      touch "$FILE"
    fi
    $notify "Matcha is enabled"
    ;;
  false)
    if test -f "$FILE"; then
      rm "$FILE"
    fi
    $notify "Matcha is disabled"
    ;;
  esac
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
