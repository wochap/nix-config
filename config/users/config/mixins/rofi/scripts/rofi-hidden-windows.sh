#!/usr/bin/env bash

nodesArray=( $(bspc query -N -n .hidden.local.window) )
rows=""

for instance in "${nodesArray[@]}"
do
  title=$(xtitle "$instance")
  class=$(xprop -id "$instance" WM_CLASS | awk -F '"' '{print $4}')
  tab=$'\t'
  nl=$'\n'
  rows+="${class}${tab}${title}${nl}"
done

s=$(echo "$rows" | column -t -s $'\t' | rofi -dmenu -format i -p  -markup-rows -theme /etc/config/rofi-clipboard-theme.rasi)

if [[ -n "$s" ]]; then
  node="${nodesArray[$s]}"
  bspc node "$node" --flag hidden=off --to-monitor focused --to-desktop focused --to-node focused --focus
fi
