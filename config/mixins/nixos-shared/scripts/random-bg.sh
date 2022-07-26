#!/usr/bin/env bash

shopt -s nullglob
cd ~/Pictures/backgrounds || exit

files=()
for i in *.jpg *.png *.jpeg; do
  [[ -f $i ]] && files+=("$i")
done
range=${#files[@]}

if [[ $XDG_SESSION_TYPE == "wayland" ]]; then
  # ((range)) && swaymsg output "*" bg "$HOME/Pictures/backgrounds/${files[RANDOM % range]}" fill
  ((range)) && swaybg -i "$HOME/Pictures/backgrounds/${files[RANDOM % range]}" -m fill
else
  ((range)) && feh --bg-fill "${files[RANDOM % range]}"
fi

