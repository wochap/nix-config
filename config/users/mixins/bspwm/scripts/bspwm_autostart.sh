#!/usr/bin/env sh

dex
/run/current-system/sw/etc/xdg/autostart/xdg-user-dirs.desktop \
  /run/current-system/sw/etc/xdg/autostart/polkit-gnome-authentication-agent-1.desktop \
  /run/current-system/sw/etc/xdg/autostart/xfce4-power-manager.desktop &
  # /run/current-system/sw/etc/xdg/autostart/org.gnome.Evolution-alarm-notify.desktop \
  # /run/current-system/sw/etc/xdg/autostart/gnome-keyring-pkcs11.desktop \
  # /run/current-system/sw/etc/xdg/autostart/gnome-keyring-ssh.desktop \
  # /run/current-system/sw/etc/xdg/autostart/tracker-miner-fs-3.desktop \
  # /run/current-system/sw/etc/xdg/autostart/gnome-keyring-secrets.desktop \
  # /run/current-system/sw/etc/xdg/autostart/xfsettingsd.desktop &

clipmenud &
picom --experimental-backends &
blueberry-tray &
caffeine -a &
/etc/scripts/polybar-start.sh &
/etc/scripts/random-bg.sh &

# light -S 20 &
# brightnessctl set 20%
