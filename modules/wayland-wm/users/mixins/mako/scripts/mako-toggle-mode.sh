#!/usr/bin/env bash

LOCK_FILE="$HOME/.cache/mako.lck"
ENABLED=
DISABLED=

toggle() {
  if [[ ! -f "$LOCK_FILE" ]]; then
    touch "$LOCK_FILE"
    makoctl set-mode do-not-disturb
    # reload waybar
    pkill -SIGRTMIN+8 waybar
  else
    rm "$LOCK_FILE"
    makoctl set-mode default
    # reload waybar
    pkill -SIGRTMIN+8 waybar
  fi
}

read() {
  if [[ ! -f "$LOCK_FILE" ]]; then
    # echo "$ENABLED"
    printf '{ "text": "%s", "class": "enabled" }' "$ENABLED"
  else
    # echo "$DISABLED"
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

