#!/usr/bin/env sh

function run {
  if ! pgrep $1 ;
  then
    $@&
  fi
}

alttab -w 1 -d 0 -sc 1 -i 224x128 -t 225x225 -s 3 -bg "#0d1117" -fg "#c9d1d9" -frame "#ff1901" -font "xft:Inter:weight=Medium:size=11" -theme "WhiteSur-dark" -mk Super_L &
alttab -w 1 -d 1 -sc 1 -i 224x128 -t 225x225 -s 3 -bg "#0d1117" -fg "#c9d1d9" -frame "#ff1901" -font "xft:Inter:weight=Medium:size=11" -theme "WhiteSur-dark" &
blueberry-tray &
clipmenud &
xsetroot -cursor_name left_ptr & # fix cursor icon
eww daemon &
caffeine &
sh /etc/scripts/polybar-start.sh &
sh /etc/fix_caps_lock_delay.sh &
