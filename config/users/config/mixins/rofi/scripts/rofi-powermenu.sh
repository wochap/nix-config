#!/usr/bin/env bash

shutdown="襤"; # "\uf924"
reboot="ﰇ"; # "\ufc07"
sleep=""; # "\uf186"
hibernate=""; # "\uf186"
logout=""; # "\uf842"
lock=""; # "\uf840"
options="$shutdown\n$reboot\n$sleep\n$logout\n$lock"

# Font size according to screen dimensions
DEFAULT_WIDTH=1920
WIDTH=$(xrandr | grep primary | awk '{print $4}' | cut -d 'x' -f 1)
DEFAULT_FONTSIZE=50
FONTSIZE=$(echo "$WIDTH/$DEFAULT_WIDTH*$DEFAULT_FONTSIZE" | bc -l)
PRESELECTION=4

selected="$(echo -e "$options" | rofi -theme /etc/config/rofi-powermenu-theme.rasi \
                                  -font "Iosevka, $FONTSIZE" \
                                  -m "primary" \
                                  -dmenu -selected-row ${PRESELECTION})"

case $selected in
  $shutdown)
    exec systemctl poweroff --check-inhibitors=no
    ;;
  $reboot)
    exec systemctl reboot
    ;;
  $hibernate)
    # Hold all on disk
    exec systemctl hibernate
    ;;
  $sleep)
    # Hold all on RAM
    mpc -q pause
    amixer set Master mute
    exec systemctl suspend
    ;;
  $logout)
    # TODO: add condition for sway
    # exec swaymsg exit
    exec bspc quit
    ;;
  $lock)
    exec /etc/scripts/lock.sh
    ;;
esac
