#!/usr/bin/env bash

clear_db() {
  cliphist wipe
}

init() {
  clear_db
  killall wl-paste
  # killall wl-clip-persist
  # TODO: wait for https://github.com/Linus789/wl-clip-persist/issues/6
  # wl-clip-persist --clipboard regular &
  wl-paste --watch cliphist store --primary
}

menu() {
  selected=$(cliphist list | rofi -p "clipboard" -dmenu -config "$HOME/.config/rofi/config-multi-line.rasi" | cliphist decode)

  if [[ -n "$selected" ]]; then
    echo -n "$selected" | wl-copy
  fi
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
