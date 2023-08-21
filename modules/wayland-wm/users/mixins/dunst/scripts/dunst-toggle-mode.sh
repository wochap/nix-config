#!/usr/bin/env bash

ENABLED=
DISABLED=

reload_waybar() {
  pkill -SIGRTMIN+8 waybar
}

toggle() {
  notify="notify-send -u low dunst"

  case $(dunstctl is-paused) in
  true)
    dunstctl set-paused false
    $notify "Notifications are enabled"
    reload_waybar
    ;;
  false)
    $notify "Notifications are being paused..."
    # the delay is here because pausing notifications immediately hides
    # the ones present on your desktop; we also run dunstctl close so
    # that the notification doesn't reappear on unpause
    (sleep 3 && dunstctl close && dunstctl set-paused true && reload_waybar) &
    ;;
  esac
}

read() {
  case $(dunstctl is-paused) in
  true)
    printf '{ "text": "%s", "class": "disabled" }' "$DISABLED"
    ;;
  false)
    printf '{ "text": "%s", "class": "enabled" }' "$ENABLED"
    ;;
  esac
}

if [[ "$1" == "--toggle" ]]; then
  toggle
elif [[ "$1" == "--read" ]]; then
  read
else
  echo -e "Available Options : --toggle --read"
fi
