#!/usr/bin/env bash

shutdown=" Shutdown"
reboot=" Reboot"
sleep=" Sleep"
hibernate=" Hibernate"
logout=" Logout"
lock=" Lock"
options="$shutdown\n$reboot\n$sleep\n$logout\n$lock"

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
"$hibernate")
  # Hold all on disk
  systemctl hibernate
  ;;
"$sleep")
  # Hold all on RAM
  systemctl suspend
  ;;
"$logout")
  systemctl --user stop graphical-session.target

  if [[ "$XDG_SESSION_DESKTOP" == 'sway' ]]; then
    swaymsg exit
  fi
  ;;
"$lock")
  /etc/scripts/sway-lock.sh
  ;;
esac
