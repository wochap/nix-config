#!/usr/bin/env bash

# HACK: window padding mess up wofi location
wofi_width="300"
wofi_padding="100"
wofi_real_width=$(echo "$wofi_width+$wofi_padding*2" | bc)
monitor_size=$(swaymsg -t get_outputs | jq '.[] | select(.focused) | .rect.width,.rect.height')
monitor_width=$(printf "$monitor_size" | sed -n '1p')
monitor_height=$(printf "$monitor_size" | sed -n '2p')
xoffset=$(echo "$monitor_width/2-$wofi_real_width/2" | bc)
yoffset="300"

shutdown=" Shutdown";
reboot=" Reboot";
sleep=" Sleep";
hibernate=" Hibernate";
logout=" Logout";
lock=" Lock";
options="$shutdown\n$reboot\n$sleep\n$logout\n$lock"

selected="$(echo -e "$options" | wofi --dmenu --width "$wofi_width" --lines 7 --location top_left --yoffset "$yoffset" --xoffset "$xoffset")"

case $selected in
  $shutdown)
    systemctl poweroff --check-inhibitors=no
    ;;
  $reboot)
    systemctl reboot
    ;;
  $hibernate)
    # Hold all on disk
    systemctl hibernate
    ;;
  $sleep)
    # Hold all on RAM
    systemctl suspend
    ;;
  $logout)
    swaymsg exit
    ;;
  $lock)
    /etc/scripts/sway-lock.sh
    ;;
esac

