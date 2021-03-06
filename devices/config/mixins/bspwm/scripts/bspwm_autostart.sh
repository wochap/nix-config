#!/usr/bin/env sh

function run {
  if ! pgrep $1 ;
  then
    $@&
  fi
}

alttab -w 1 -d 0 -sc 1 -i 224x128 -t 225x225 -s 3 -bg "#0d1117" -fg "#c9d1d9" -frame "#58a6ff" -font "xft:Iosevka:weight=bold:size=12" -theme "WhiteSur-dark" -mk Super_L &
alttab -w 1 -d 1 -sc 1 -i 224x128 -t 225x225 -s 3 -bg "#0d1117" -fg "#c9d1d9" -frame "#58a6ff" -font "xft:Iosevka:weight=bold:size=12" -theme "WhiteSur-dark" &
blueberry-tray &
clipmenud &
xsetroot -cursor_name left_ptr & # fix cursor icon
eww daemon &
caffeine &
polybar main -r &
sh /etc/fix_caps_lock_delay.sh &
