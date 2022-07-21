#!/usr/bin/env sh

dex /run/current-system/sw/etc/xdg/autostart/xdg-user-dirs.desktop \
  /run/current-system/sw/etc/xdg/autostart/polkit-gnome-authentication-agent-1.desktop &

# TODO: move to systemd
kanshi &

# clipboard
wl-copy " " &
# TODO: use cliphist
clipman clear --all &
wl-paste --watch clipman store --primary &

# /etc/scripts/import-gsettings.sh &
# TODO: move to systemd
mako &
# TODO: move to systemd
gammastep -O 4000 &
# TODO: move to systemd
waybar &
blueberry-tray &
/etc/scripts/backlight.sh 20% &
# TODO: move to systemd
/etc/scripts/random-bg.sh &
# /etc/scripts/restart_goa_daemon.sh &

