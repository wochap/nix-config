#!/usr/bin/env bash

clear_db() {
  rm "$XDG_CACHE_HOME/cliphist/db"
}

init() {
  clear_db
  killall wl-paste
  wl-paste --watch cliphist store --primary
}

menu() {
  selected=$(cliphist list | rofi -p "clipboard" -dmenu -config "$HOME/.config/rofi/config-multi-line.rasi" | cliphist decode)

  if [[ -n "$selected" ]]; then
    echo -n "$selected" | wl-copy
  fi

  # cliphist list | wofi --dmenu --width "600" --location top | cliphist decode | wl-copy
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