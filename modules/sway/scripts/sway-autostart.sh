#!/usr/bin/env sh

dex /run/current-system/sw/etc/xdg/autostart/xdg-user-dirs.desktop \
  /run/current-system/sw/etc/xdg/autostart/polkit-gnome-authentication-agent-1.desktop &

# TODO: move to systemd
# kanshi &

# clipboard manager
/etc/scripts/system/clipboard-manager.sh --start

# TODO: move to systemd
/etc/scripts/mako/mako-start.sh &

# TODO: move to systemd
killall gammastep
gammastep -O 4000 &

# TODO: move to systemd
/etc/scripts/waybar/waybar-start.sh &

# turn off bluetooth to save battery
bluetoothctl power off &

libinput-gestures -c /etc/libinput-gestures.conf &

# blueberry-tray &
/etc/scripts/backlight.sh 20% &
# /etc/scripts/system/random-bg.sh &
swaybg -c "#282a36" -m fill -i "$HOME/Pictures/backgrounds/dracula.jpeg" &
# HACK: make swaybg visible?
swaymsg "output * background #282a36 solid_color" &

