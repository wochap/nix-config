#!/usr/bin/env bash

getBWindowyId() {
  xdo id -N eww-border
}

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

openBWindow() {
  closeBWindow
  wid="$1"

  if [ -z "$wid" ]; then
    return 1
  fi

  if [ "$wid" != "$(pfw)" ]; then
    return 1
  fi

  borderW="3"
  focusedW=$(wattr w "$wid")
  focusedH=$(wattr h "$wid")
  focusedX=$(wattr x "$wid")
  focusedY=$(wattr y "$wid")
  echo "$wid"
  echo "$focusedW"

  eww open border -p "$((focusedX - borderW))x$((focusedY - borderW))" -s "$((focusedW + borderW * 2))x$((focusedH + borderW * 2))" > /dev/null 2>&1


  # wait for it to open
  # eww_wid="$(xdotool search --name 'Eww - border' || true)"
  # while [ -z "$eww_wid" ]; do
  #   # open eww widget
  #   eww open border > /dev/null 2>&1
  #   sleep 0.1
  #   eww_wid="$(xdotool search --name 'Eww - border' || true)"
  # done

  # echo "$(getBWindowyId)"
}

# sub to focus, rezise, workspace window
  # if no window focus
    # hide
  # if window focus, rezise
    # if border open close
    # show on focused window position, lower

bspc subscribe node_focus node_geometry node_remove desktop_focus | while read -r _ _ _ node; do
  openBWindow "$(pfw)"
done

echo "hello2"

