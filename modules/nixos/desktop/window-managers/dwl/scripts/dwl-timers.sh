#!/usr/bin/env bash

# Focus DWL tag 9
# 125 = logo
# 10 = 9
ydotool key 125:1 10:1 10:0 125:0

if [[ -z $(pgrep "gnome-pomodoro") ]]; then
  gnome-pomodoro &
fi

if [[ -z $(pgrep "gnome-clocks") ]]; then
  gnome-clocks &
fi
