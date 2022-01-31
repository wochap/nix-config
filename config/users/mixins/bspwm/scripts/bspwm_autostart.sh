#!/usr/bin/env sh

dex
  /run/current-system/sw/etc/xdg/autostart/org.gnome.Evolution-alarm-notify.desktop \
  /run/current-system/sw/etc/xdg/autostart/xdg-user-dirs.desktop \
  /run/current-system/sw/etc/xdg/autostart/polkit-gnome-authentication-agent-1.desktop \
  /run/current-system/sw/etc/xdg/autostart/xfce4-power-manager.desktop &
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
/etc/scripts/restart_goa_daemon.sh &

# light -S 20 &
# sh /etc/scripts/eww_start.sh &
# alttab -w 1 -d 0 -sc 1 -i 224x128 -t 225x225 -s 3 -bg "#282a36" -fg "#f8f8f2" -frame "#ff79c6" -font "xft:Inter:weight=Medium:size=11" -theme "WhiteSur-dark" &
