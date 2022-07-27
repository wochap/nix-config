#!/usr/bin/env sh

dex /run/current-system/sw/etc/xdg/autostart/xdg-user-dirs.desktop \
  /run/current-system/sw/etc/xdg/autostart/polkit-gnome-authentication-agent-1.desktop &

# TODO: move to systemd
# kanshi &

# clipboard manager
/etc/scripts/system/clipboard-manager.sh --start

# TODO: move to systemd
killall mako
mako &

# TODO: move to systemd
killall gammastep
gammastep -O 4000 &

# TODO: move to systemd
killall waybar
waybar &

# blueberry-tray &
/etc/scripts/backlight.sh 20% &
/etc/scripts/system/random-bg.sh &
