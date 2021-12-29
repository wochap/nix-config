#!/usr/bin/env bash

# getBWindowyId() {
#   result=$(xdo id -N eww-border)
#   echo "${result^^}"
# }

closeBWindow() {
  # wait for it to close
  eww_wid="$(xdotool search --name 'Eww - border' || true)"
  while [ -n "$eww_wid" ]; do
    # close eww widget
    eww close border > /dev/null 2>&1
    sleep 0.1
    eww_wid="$(xdotool search --name 'Eww - border' || true)"
  done
}

lastBorderPosition=""
openBWindow() {
  wid="$1"

  if [ -z "$wid" ]; then
    # no focused window
    closeBWindow
    return 1
  fi

  if [ "$wid" != "$(pfw)" ]; then
    # focused window changed
    return 1
  fi

  focusedW=$(wattr w "$wid")
  focusedH=$(wattr h "$wid")
  focusedX=$(wattr x "$wid")
  focusedY=$(wattr y "$wid")

  # do nothing if border pos didnt change
  newBorderPosition="$focusedW $focusedH $focusedX $focusedY"
  if [ "$lastBorderPosition" == "$newBorderPosition" ]; then
    return 1
  fi
  lastBorderPosition="$newBorderPosition"

  echo "$wid"
  closeBWindow

  # render border behind focused window
  # BSPWM specific
  floating_wids=$(bspc query --nodes --node .floating.focused)
  if [[ -n $floating_wids ]]; then
    bspc rule -a "eww-border" layer=normal state=floating hidden=on focus=off
  else
    bspc rule -a "eww-border" layer=below state=floating hidden=on focus=off
  fi

  borderW="3"
  eww open border -p "$((focusedX - borderW))x$((focusedY - borderW))" -s "$((focusedW + borderW * 2))x$((focusedH + borderW * 2))" > /dev/null 2>&1
  sleep 0.1

  if [ "$wid" != "$(pfw)" ]; then
    # focused window changed
    return 1
  fi

  bspc node "$(xdo id -N eww-border)" --flag hidden=off
  # xdotool set_window --overrideredirect 1 "$(xdo id -N eww-border)"
  # xdo hide "$(xdo id -N eww-border)"
  # xdo show "$(xdo id -N eww-border)"
  # xdo below -t "$(pfw)" "$(xdo id -N eww-border)"
}

bspc subscribe node_focus node_geometry node_remove node_state pointer_action desktop_focus | while read -r _ _ _ node; do
  if [ "$(atomx WM_CLASS $node)" == "eww-border" ]; then
    continue
  fi
  openBWindow "$(pfw)"
done

