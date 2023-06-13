#!/usr/bin/env bash

dex /run/current-system/sw/etc/xdg/autostart/xdg-user-dirs.desktop \
  /run/current-system/sw/etc/xdg/autostart/tracker-miner-fs-3.desktop \
  /run/current-system/sw/etc/xdg/autostart/polkit-gnome-authentication-agent-1.desktop \
  /run/current-system/sw/etc/xdg/autostart/xfce4-power-manager.desktop &

xsettingsd &

# autorandr hooks runs random-bg, polybar and dunst
if [[ $(autorandr | grep "detected" | wc -l) -eq 0 ]]; then
  /etc/scripts/random-bg.sh &
  /home/gean/.config/autorandr/postswitch.d/change-dpi &
else
  autorandr --change &
fi

clipmenud &
picom --experimental-backends &
caffeine -a &
libinput-gestures -c /etc/libinput-gestures.conf &

/etc/scripts/backlight.sh 20% &

# sudo cpupower frequency-set -g powersave
# sudo cpupower frequency-set --related --max 2800000
# sudo cpupower frequency-set --related --min 800000
