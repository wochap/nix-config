#!/usr/bin/env sh

dex /run/current-system/sw/etc/xdg/autostart/xdg-user-dirs.desktop \
  /run/current-system/sw/etc/xdg/autostart/polkit-gnome-authentication-agent-1.desktop &

# TODO: move to systemd
# kanshi &

# clipboard manager
/etc/scripts/system/clipboard-manager.sh --start

# TODO: move to systemd
mako &

# TODO: move to systemd
gammastep -O 4000 &

# TODO: move to systemd
waybar &

/etc/scripts/backlight.sh 20% &
/etc/scripts/system/random-bg.sh &

