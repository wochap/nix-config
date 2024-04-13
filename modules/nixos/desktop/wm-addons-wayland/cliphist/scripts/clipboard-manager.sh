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
  list=$(cliphist list |
    sort -k 2 -u | # sort by 2 field to the end of line and output only unique lines
    sort -nr) # sort numerically in reverse
  list_count=$(if [[ -z "$list" ]]; then echo 0; else echo "$list" | wc -l; fi)
  num_results=$(if [[ "$list_count" -gt 10 ]]; then echo 10; else echo "$list_count"; fi)
  height=$(if [[ "$num_results" -gt 0 ]]; then echo "scale=0; ($num_results * 29.20) + 11 + 40" | bc -l | awk '{print int($1+0.5)}'; else echo 40; fi)
  selected=$(echo "$list" |
    tofi \
      --height "$height" \
      --num-results "$num_results" \
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
