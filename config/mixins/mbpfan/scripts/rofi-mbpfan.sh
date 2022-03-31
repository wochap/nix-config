#!/usr/bin/env bash

PRESELECTION=2

default="Default (2500)"
high="High (4500)"
higher="Higher (5500)"
options="$default\n$high\n$higher"

selected="$(echo -e "$options" | rofi \
  -p "RPM" \
  -theme-str 'window { width: 15em; }' \
  -dmenu \
  -i \
  -selected-row ${PRESELECTION})"

case $selected in
"$default")
  sed --follow-symlinks --in-place -E "/min_fan1_speed=/c\min_fan1_speed=2500" "/etc/mbpfan.conf"
  sed --follow-symlinks --in-place -E "/min_fan2_speed=/c\min_fan2_speed=2500" "/etc/mbpfan.conf"
  ;;
"$high")
  sed --follow-symlinks --in-place -E "/min_fan1_speed=/c\min_fan1_speed=4500" "/etc/mbpfan.conf"
  sed --follow-symlinks --in-place -E "/min_fan2_speed=/c\min_fan2_speed=4500" "/etc/mbpfan.conf"
  ;;
"$higher")
  sed --follow-symlinks --in-place -E "/min_fan1_speed=/c\min_fan1_speed=5500" "/etc/mbpfan.conf"
  sed --follow-symlinks --in-place -E "/min_fan2_speed=/c\min_fan2_speed=5500" "/etc/mbpfan.conf"
  ;;
esac

# killall mbpfan
# sudo mbpfan -fv
systemctl restart mbpfan.service
# cat /sys/devices/platform/applesmc.768/fan*_output
