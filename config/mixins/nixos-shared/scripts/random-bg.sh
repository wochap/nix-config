#!/usr/bin/env bash

shopt -s nullglob
cd ~/Pictures/backgrounds

files=()
for i in *.jpg *.png *.jpeg; do
  [[ -f $i ]] && files+=("$i")
done
range=${#files[@]}

if [[ $XDG_SESSION_TYPE == "wayland" ]]; then
  ((range)) && swaymsg output "*" bg "~/Pictures/backgrounds/${files[RANDOM % range]}" fill
else
  ((range)) && feh --bg-fill "${files[RANDOM % range]}"
fi

