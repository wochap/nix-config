#!/usr/bin/env sh

dex /run/current-system/sw/etc/xdg/autostart/xdg-user-dirs.desktop &

# kanshi &

# turn off bluetooth to save battery
bluetoothctl power off &

/etc/scripts/backlight.sh 20% &

