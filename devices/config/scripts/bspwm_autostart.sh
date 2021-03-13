#!/usr/bin/env sh

function run {
  if ! pgrep $1 ;
  then
    $@&
  fi
}

nitrogen --restore &
alttab -w 1 -d 0 -sc 1 -i 199x64 -t 200x200 -s 3 -bg "#0d1117" -fg "#c9d1d9" -frame "#58a6ff" -font "xft:Iosevka:weight=bold:size=12" -theme "WhiteSur-dark" -mk Super_L &
alttab -w 1 -d 1 -sc 1 -i 199x64 -t 200x200 -s 3 -bg "#0d1117" -fg "#c9d1d9" -frame "#58a6ff" -font "xft:Iosevka:weight=bold:size=12" -theme "WhiteSur-dark" &
blueberry-tray &
clipmenud &
xsetroot -cursor_name left_ptr & # fix cursor icon
eww daemon &
caffeine &
polybar main -r &

echo "$(pulsemixer --get-volume | awk '{print $1}')" > /tmp/vol &
/etc/eww_vol_icon.sh mute

/etc/fix_caps_lock_delay.sh
