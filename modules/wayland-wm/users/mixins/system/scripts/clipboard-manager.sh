#!/usr/bin/env bash

clear_db() {
  rm "$XDG_CACHE_HOME/cliphist/db"
}

init() {
  clear_db
  wl-paste --watch cliphist store --primary &
}

menu() {
  cliphist list | wofi --dmenu --location top | cliphist decode | wl-copy
}

if [[ "$1" == "--start" ]]; then
  init
elif [[ "$1" == "--menu" ]]; then
  menu
elif [[ "$1" == "--clear" ]]; then
  clear_db
else
  echo -e "Available Options : --start --menu --clear"
fi

exit 0

