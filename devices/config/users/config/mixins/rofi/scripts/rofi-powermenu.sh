#!/usr/bin/env bash

# Options as characters
# Copied from decoded unicodes (private use of "Feather" font)
shutdown="襤"; # "\uf924"
reboot="ﰇ"; # "\ufc07"
sleep=""; # "\uf186"
logout=""; # "\uf842"
lock=""; # "\uf840"
# shutdown=""; # "\uE9C0"
# reboot=""; # "\uE9C4"
# sleep=""; # "\uE9A3"
# logout=""; # "\uE991"
# lock=""; # "\uE98F"
options="$shutdown\n$reboot\n$sleep\n$logout\n$lock"

# Font size according to screen dimensions
DEFAULT_WIDTH=1920
WIDTH=$(xrandr | grep primary | awk '{print $4}' | cut -d 'x' -f 1)
DEFAULT_FONTSIZE=50
FONTSIZE=$(echo "$WIDTH/$DEFAULT_WIDTH*$DEFAULT_FONTSIZE" | bc -l)

while getopts "lp" OPT; do
  case "$OPT" in
    p) PRESELECTION=0 ;;
    l) PRESELECTION=3 ;;
    *) PRESELECTION=4 ;;
  esac
done

if (( $OPTIND == 1 )); then
  PRESELECTION=4
fi

selected="$(echo -e "$options" |
  rofi -theme /etc/config/rofi-powermenu-theme.rasi \
    -font "Iosevka, $FONTSIZE" \
    -m "primary" \
    -dmenu -selected-row ${PRESELECTION})"

case $selected in
  $shutdown)
    systemctl poweroff
    ;;
  $reboot)
    systemctl reboot
    ;;
  $sleep)
    mpc -q pause
    amixer set Master mute
    systemctl suspend
    ;;
  $logout)
    bspc quit
    ;;
  $lock)
    betterlockscreen -l
    ;;
esac
