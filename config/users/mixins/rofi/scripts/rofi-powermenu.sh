#!/usr/bin/env bash

shutdown=" Shutdown";
reboot=" Reboot";
sleep=" Sleep";
hibernate=" Hibernate";
logout=" Logout";
lock=" Lock";
options="$shutdown\n$reboot\n$sleep\n$logout\n$lock"

PRESELECTION=4

selected="$(echo -e "$options" | rofi \
  -p "" \
  -theme-str 'window { width: 15em; }' \
  -theme-str 'element-text {font: "woos 12";}' \
  -dmenu \
  -i \
  -selected-row ${PRESELECTION})"

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
    bspc quit
    ;;
  $lock)
    /etc/scripts/lock.sh
    ;;
esac
