#!/usr/bin/env bash

nodes=$(bspc query -N -n .hidden.local.window)
rows=""
while read -r instance; do
  title=$(xtitle "$instance")
  class=$(xprop -id "$instance" WM_CLASS | awk -F '"' '{print $4}')
  tab=$'\t'
  rows+="${class}${tab}${title}"
done <<<"${nodes}"

s=$(echo "$rows" | column -t -s $'\t' | rofi -dmenu -format -i -p  -markup-rows -theme /etc/config/rofi-clipboard-theme.rasi)

if [[ -n "$s" ]]; then
  bspc node "${nodes[$s]}" -n focused -g hidden=off -f
fi

