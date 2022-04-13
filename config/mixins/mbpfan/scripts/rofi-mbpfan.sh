#!/usr/bin/env bash

PRESELECTION=2

default="Default (2500)"
normal="Normal (3500)"
high="High (4500)"
higher="Higher (5500)"
options="$default\n$high\n$higher"

selected="$(echo -e "$options" | rofi \
  -p "RPM" \
  -theme-str 'window { width: 15em; }' \
  -dmenu \
  -i \
  -selected-row ${PRESELECTION})"

reloadMbpfan() {
  # killall mbpfan
  # sudo mbpfan -fv
  systemctl restart mbpfan.service
}

case $selected in
"$default")
  sed --follow-symlinks --in-place -E "/min_fan1_speed=/c\min_fan1_speed=2500" "/etc/mbpfan.conf"
  sed --follow-symlinks --in-place -E "/min_fan2_speed=/c\min_fan2_speed=2500" "/etc/mbpfan.conf"
  reloadMbpfan &
  ;;
"$normal")
  sed --follow-symlinks --in-place -E "/min_fan1_speed=/c\min_fan1_speed=3500" "/etc/mbpfan.conf"
  sed --follow-symlinks --in-place -E "/min_fan2_speed=/c\min_fan2_speed=3500" "/etc/mbpfan.conf"
  reloadMbpfan &
  ;;
"$high")
  sed --follow-symlinks --in-place -E "/min_fan1_speed=/c\min_fan1_speed=4500" "/etc/mbpfan.conf"
  sed --follow-symlinks --in-place -E "/min_fan2_speed=/c\min_fan2_speed=4500" "/etc/mbpfan.conf"
  reloadMbpfan &
  ;;
"$higher")
  sed --follow-symlinks --in-place -E "/min_fan1_speed=/c\min_fan1_speed=5500" "/etc/mbpfan.conf"
  sed --follow-symlinks --in-place -E "/min_fan2_speed=/c\min_fan2_speed=5500" "/etc/mbpfan.conf"
  reloadMbpfan &
  ;;
esac