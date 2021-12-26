#!/usr/bin/env bash

wew | while read -r evwid; do
  ev=$(echo "$evwid" | cut -d ':' -f 1)
  wid=$(echo "$evwid" | cut -d ':' -f 2)

  if [[ "$ev" == "16" ]]; then
    wclass=$(xprop -id "$wid" WM_CLASS | awk '{print $4}' | sed -e 's/^"//' -e 's/"$//')
    if [[ "$wclass" == "eww-border" ]]; then
      # eww border window has been opened
      echo "$evwid"
      echo "$ev"
      echo "$wid"
      echo "$wclass"
      # send eww border window to the bg
      chwso -l "$wid" 
    fi
  fi
done

