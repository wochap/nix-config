#!/usr/bin/env sh

dex /run/current-system/sw/etc/xdg/autostart/xdg-user-dirs.desktop \
  /run/current-system/sw/etc/xdg/autostart/polkit-gnome-authentication-agent-1.desktop &

# kanshi &

libinput-gestures -c /etc/libinput-gestures.conf &

/etc/scripts/backlight.sh 20% &

# sudo cpupower frequency-set -g powersave
# sudo cpupower frequency-set --related --max 2800000
# sudo cpupower frequency-set --related --max 4000000
# sudo cpupower frequency-set --related --min 800000
