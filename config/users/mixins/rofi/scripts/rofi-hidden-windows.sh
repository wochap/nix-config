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

s=$(printf "$rows" | column -t -s "$(printf '\t')" | rofi -font "FiraCode Nerd Font Mono 11" -format i -dmenu -i -p "" -markup-rows -theme /etc/config/rofi-clipboard-theme.rasi)

if [[ -n "$s" ]]; then
  node="${nodesArray[$s]}"
  bspc node "$node" --flag hidden=off --focus
fi