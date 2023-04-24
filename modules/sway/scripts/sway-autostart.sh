#!/usr/bin/env sh

dex /run/current-system/sw/etc/xdg/autostart/xdg-user-dirs.desktop \
  /run/current-system/sw/etc/xdg/autostart/polkit-gnome-authentication-agent-1.desktop &

# kanshi &

# turn off bluetooth to save battery
bluetoothctl power off &

libinput-gestures -c /etc/libinput-gestures.conf &

/etc/scripts/backlight.sh 20% &

