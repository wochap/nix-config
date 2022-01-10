#!/usr/bin/env bash

shopt -s nullglob
cd ~/Pictures/backgrounds

files=()
for i in *.jpg *.png *.jpeg; do
  [[ -f $i ]] && files+=("$i")
done
range=${#files[@]}

((range)) && feh --bg-fill "${files[RANDOM % range]}"

