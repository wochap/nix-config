#!/usr/bin/env bash

shutdown=" Shutdown";
reboot=" Reboot";
sleep=" Sleep";
hibernate=" Hibernate";
logout=" Logout";
lock=" Lock";
options="$shutdown\n$reboot\n$sleep\n$logout\n$lock"

PRESELECTION=4

selected="$(echo -e "$options" | rofi -p "powermenu" -dmenu \
  -config "$HOME/.config/rofi/config-one-line.rasi" \
  -selected-row ${PRESELECTION} \
  -theme-str 'mainbox {children: [ "prompt", "listview" ];} element-text {font: "Iosevka Nerd Font, woos 28px";}')"

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
