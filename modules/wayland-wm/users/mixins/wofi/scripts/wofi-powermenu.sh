#!/usr/bin/env bash

wofi_width="300"
shutdown=" Shutdown";
reboot=" Reboot";
sleep=" Sleep";
hibernate=" Hibernate";
logout=" Logout";
lock=" Lock";
options="$shutdown\n$reboot\n$sleep\n$logout\n$lock"

selected="$(echo -e "$options" | wofi --dmenu --width "$wofi_width" --lines 5 --location top)"

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

