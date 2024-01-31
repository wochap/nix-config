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
  wl-paste --type text --watch cliphist store --primary
}

menu() {
  selected=$(cliphist list |
    sort -k 2 -u | # sort by 2 field to the end of line and output only unique lines
    sort -nr |     # sort numerically in reverse
    tofi \
      --prompt-text "clipboard" \
      --config "$HOME/.config/tofi/multi-line" |
    cliphist decode)

  if [ -n "$selected" ]; then
    printf "%s" "$selected" | wl-copy --trim-newline --type text/plain
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
