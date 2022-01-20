#!/usr/bin/env sh

function run {
  if ! pgrep $1 ;
  then
    $@
  fi
}

# alttab -w 1 -d 0 -sc 1 -i 224x128 -t 225x225 -s 3 -bg "#282a36" -fg "#f8f8f2" -frame "#ff79c6" -font "xft:Inter:weight=Medium:size=11" -theme "WhiteSur-dark" &
clipmenud &
picom --experimental-backends &
blueberry-tray &
caffeine -a &
/etc/scripts/polybar-start.sh &
/etc/scripts/start-minimal-xfce4.sh &
sleep 2
/etc/scripts/random-bg.sh &
# TODO: add evolution-data-server
# evolution-data-server / libexec / evolution-data-server / evolution-alarm-notyfy
# sh /etc/scripts/fix_caps_lock_delay.sh &
# sh /etc/scripts/eww_start.sh &
