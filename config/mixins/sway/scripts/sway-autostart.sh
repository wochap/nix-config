#!/usr/bin/env sh

dex /run/current-system/sw/etc/xdg/autostart/org.gnome.Evolution-alarm-notify.desktop \
  /run/current-system/sw/etc/xdg/autostart/xdg-user-dirs.desktop &

wl-paste --watch clipman store --primary &
waybar &
blueberry-tray &
# light -S 20 &
brightnessctl set 20%
sleep 2
/etc/scripts/random-bg.sh &



