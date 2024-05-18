#!/usr/bin/env bash

shutdown=" Shutdown"
reboot=" Reboot"
suspend=" Suspend"
logout=" Logout"
lock=" Lock"
options="$shutdown\n$reboot\n$suspend\n$logout\n$lock"

selected="$(echo -e "$options" |
  tofi \
    --prompt-text "powermenu" \
    --config "$HOME/.config/tofi/one-line")"

case $selected in
"$shutdown")
  systemctl poweroff --check-inhibitors=no
  ;;
"$reboot")
  systemctl reboot
  ;;
"$suspend")
  # Hold all on RAM
  systemctl suspend
  ;;
"$logout")
  systemctl --user stop graphical-session.target --quiet
  systemctl --user stop wayland-session.target --quiet

  if [[ "$XDG_SESSION_DESKTOP" == 'sway' ]]; then
    swaymsg exit
  fi
  if [[ "$XDG_SESSION_DESKTOP" == 'Hyprland' ]]; then
    hyprctl dispatch exit
  fi
  if [[ "$XDG_SESSION_DESKTOP" == 'dwl' ]]; then
    # simulate logo + ctrl + shift + q key press
    ydotool key 125:1 29:1 42:1 16:1 16:0 42:0 29:0 125:0
  fi
  ;;
"$lock")
  /etc/scripts/sway-lock.sh
  ;;
esac
