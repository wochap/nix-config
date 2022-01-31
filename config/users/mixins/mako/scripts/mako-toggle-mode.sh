#!/usr/bin/env bash

LOCK_FILE="$HOME/.cache/mako.lck"
ENABLED=
DISABLED=

toggle() {
  if [[ ! -f "$LOCK_FILE" ]]; then
    touch "$LOCK_FILE"
    makoctl set-mode do-not-disturb
  else
    rm "$LOCK_FILE"
    makoctl set-mode default
  fi
}

read() {
  if [[ ! -f "$LOCK_FILE" ]]; then
    echo "$ENABLED"
  else
    echo "$DISABLED"
  fi
}

if [[ "$1" == "--toggle" ]]; then
  toggle
elif [[ "$1" == "--read" ]]; then
  read
else
  echo -e "Available Options : --toggle --read"
fi

