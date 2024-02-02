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
  systemctl --user stop wayland-session.target

  if [[ "$XDG_SESSION_DESKTOP" == 'sway' ]]; then
    swaymsg exit
  fi
  ;;
"$lock")
  /etc/scripts/sway-lock.sh
  ;;
esac
