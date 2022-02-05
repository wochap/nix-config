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

xsettingsd &

if [ -x "$(command -v nvidia-settings)" ]; then
  nvidia-settings --assign CurrentMetaMode="nvidia-auto-select +0+0 {ForceFullCompositionPipeline=On, AllowGSYNCCompatible=On}"
fi

# autorandr hooks runs random-bg, polybar and dunst
autorandr --load desktop-4k &
# /etc/scripts/polybar-start.sh &
# /etc/scripts/dunst-start.sh &
# /etc/scripts/random-bg.sh &

clipmenud &
# picom --experimental-backends &
blueberry-tray &
caffeine -a &

# light -S 20 &
# brightnessctl set 20%
