#!/usr/bin/env sh

dex /run/current-system/sw/etc/xdg/autostart/org.gnome.Evolution-alarm-notify.desktop \
  /run/current-system/sw/etc/xdg/autostart/xdg-user-dirs.desktop &

# clipboard
wl-copy " "
clipman clear --all
wl-paste --watch clipman store --primary &

/etc/scripts/import-gsettings.sh &
mako &
gammastep -O 4000 &
waybar &
blueberry-tray &
# light -S 20 &
brightnessctl set 20%
/etc/scripts/random-bg.sh &
# /etc/scripts/restart_goa_daemon.sh &

