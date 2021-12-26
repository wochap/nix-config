#!/usr/bin/env bash

wew | while read -r evwid; do
  ev=$(echo "$evwid" | cut -d ':' -f 1)
  wid=$(echo "$evwid" | cut -d ':' -f 2)

  if [[ "$ev" == "16" ]]; then
    wclass=$(xprop -id "$wid" WM_CLASS | awk '{print $4}' | sed -e 's/^"//' -e 's/"$//')
    if [[ "$wclass" == "eww-border" ]]; then
      # eww border window has been opened
      # echo "$evwid"
      # echo "$ev"
      echo "wid $wid"
      # echo "$wclass"

      # if focused window is floating
      # send eww border window to the top
      # send focused window to the top 
      focusedWid=$(bspc query --nodes --node .focused)
      floating_wids=$(bspc query --nodes --node .floating.focused)
      if [[ -n $floating_wids ]]; then
        echo "it is floating"
        # chwso -r "$wid"
        # chwso will trigger resize on the focused node
        # chwso -r "$floating_wids"
        # xdo below -t "$floating_wids" "$wid"
        # xdo above -t "$wid" "$floating_wids"
        # xdo below -t "$wid" "$floating_wids"
        echo $floating_wids
      else
        echo "no floating"
        # send eww border window to the bg
        # chwso -l "$wid"
      fi
      # xdo below -t "$focusedWid" "$wid"

    fi
  fi
done

