#!/usr/bin/env bash

# HACK: window padding mess up wofi location
wofi_width="300"
wofi_padding="100"
wofi_real_width=$(echo "$wofi_width+$wofi_padding*2" | bc)
monitor_size=$(swaymsg -t get_outputs | jq '.[] | select(.focused) | .rect.width,.rect.height')
monitor_width=$(printf "$monitor_size" | sed -n '1p')
monitor_height=$(printf "$monitor_size" | sed -n '2p')
xoffset=$(echo "$monitor_width/2-$wofi_real_width/2" | bc)
yoffset=$(echo "$monitor_height*0.2" | bc)

default="Default (2500)"
normal="Normal (3500)"
high="High (4500)"
higher="Higher (5500)"
options="$default\n$normal\n$high\n$higher"

selected="$(echo -e "$options" | wofi \
  --dmenu \
  --width "$wofi_width" \
  --lines 7 \
  --location top_left \
  --yoffset "$yoffset" \
  --xoffset "$xoffset")"

case $selected in
"$default")
  sed --follow-symlinks --in-place -E "/min_fan1_speed=/c\min_fan1_speed=2500" "/etc/mbpfan.conf"
  sed --follow-symlinks --in-place -E "/min_fan2_speed=/c\min_fan2_speed=2500" "/etc/mbpfan.conf"
  ;;
"$normal")
  sed --follow-symlinks --in-place -E "/min_fan1_speed=/c\min_fan1_speed=3500" "/etc/mbpfan.conf"
  sed --follow-symlinks --in-place -E "/min_fan2_speed=/c\min_fan2_speed=3500" "/etc/mbpfan.conf"
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
