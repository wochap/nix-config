#!/usr/bin/env sh

function run {
  if ! pgrep $1 ;
  then
    $@&
  fi
}

alttab -w 1 -d 0 -sc 1 -i 224x128 -t 225x225 -s 3 -bg "#282a36" -fg "#f8f8f2" -frame "#ff79c6" -font "xft:Inter:weight=Medium:size=11" -theme "WhiteSur-dark" -mk Super_L &
blueberry-tray &
clipmenud &
xsetroot -cursor_name left_ptr & # fix cursor icon
eww daemon &
caffeine -a &
sh /etc/scripts/polybar-start.sh &
sh /etc/scripts/fix_caps_lock_delay.sh &
