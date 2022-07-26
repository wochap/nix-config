#!/usr/bin/env bash

init() {
  rm "$XDG_CACHE_HOME/cliphist/db"
  wl-paste --watch cliphist store --primary &
}

menu() {
  cliphist list | wofi --dmenu --location top | cliphist decode | wl-copy
}

if [[ "$1" == "--start" ]]; then
  init
elif [[ "$1" == "--menu" ]]; then
  menu
else
  echo -e "Available Options : --start --menu"
fi

exit 0

