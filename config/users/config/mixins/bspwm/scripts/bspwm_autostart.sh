#!/usr/bin/env sh

function run {
  if ! pgrep $1 ;
  then
    $@&
  fi
}

# alttab -w 1 -d 0 -sc 1 -i 224x128 -t 225x225 -s 3 -bg "#282a36" -fg "#f8f8f2" -frame "#ff79c6" -font "xft:Inter:weight=Medium:size=11" -theme "WhiteSur-dark" &
clipmenud &
picom --experimental-backends &
blueberry-tray &
caffeine -a &
sh /etc/scripts/polybar-start.sh &
sh /etc/scripts/random-bg.sh &
sh /etc/scripts/start-minimal-xfce4.sh &
# TODO: add evolution
# sh /etc/scripts/fix_caps_lock_delay.sh &
# sh /etc/scripts/eww_start.sh &
