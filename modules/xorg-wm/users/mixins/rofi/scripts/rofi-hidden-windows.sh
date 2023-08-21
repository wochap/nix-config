#!/usr/bin/env bash

query=${NODES_QUERY:-.hidden.local.window}
nodesArray=( $(bspc query -N -n $query) )
rows=""

for instance in "${nodesArray[@]}"
do
  title=$(xtitle "$instance")
  class=$(xprop -id "$instance" WM_CLASS | awk -F '"' '{print $4}')
  rows+="<span>${class}\t${title}</span>\n"
done

s=$(printf "$rows" | column -t -s "$(printf '\t')" | rofi -config "$HOME/.config/rofi/config-multi-line.rasi" -format i -dmenu -i -p "hidden windows" -markup-rows)

if [[ -n "$s" ]]; then
  node="${nodesArray[$s]}"
  bspc node "$node" --flag hidden=off --focus
fi
