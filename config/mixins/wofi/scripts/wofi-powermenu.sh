#!/usr/bin/env bash

shutdown="";
reboot="";
sleep="";
hibernate="";
logout="";
lock="";
options="$shutdown\n$reboot\n$sleep\n$logout\n$lock"

# Font size according to screen dimensions
FOCUSED_MONITOR=$(bspc query --monitors --monitor .focused --names)
DEFAULT_WIDTH=1920
WIDTH=$(xrandr | grep "$FOCUSED_MONITOR" | awk '{print $4}' | cut -d 'x' -f 1)
if [[ "$WIDTH" == "(normal" ]]; then
  WIDTH=$(xrandr | grep "$FOCUSED_MONITOR" | awk '{print $3}' | cut -d 'x' -f 1)
fi
DEFAULT_FONTSIZE=39
FONTSIZE=$(echo "$WIDTH/$DEFAULT_WIDTH*$DEFAULT_FONTSIZE" | bc -l)
PRESELECTION=4

selected="$(echo -e "$options" | rofi -theme /etc/config/rofi-powermenu-theme.rasi \
                                  -font "woos, $FONTSIZE" \
                                  -m -1 \
                                  -dmenu -selected-row ${PRESELECTION})"

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
    # TODO: add condition for sway
    # exec swaymsg exit
    bspc quit
    ;;
  $lock)
    /etc/scripts/lock.sh
    ;;
esac

