#!/usr/bin/env sh

function run {
  if ! pgrep $1 ;
  then
    $@&
  fi
}

nitrogen --restore &
alttab -w 1 -d 1 -sc 0 -i 199x64 -t 200x200 -s 3 -bg "#1C1E27" -fg "#cacacc" -frame "#a0c3ff" -font "xft:Roboto:weight=bold:size=11" -theme "WhiteSur-dark" &
blueberry-tray &
clipmenud &
xsetroot -cursor_name left_ptr & # fix cursor size for 4k display
eww daemon &
polybar main -r &

echo "$(pulsemixer --get-volume | awk '{print $1}')" > /tmp/vol &
/etc/eww_vol_icon.sh mute
