#!/usr/bin/env bash

ENABLED=
DISABLED=

toggle() {
  notify="notify-send -u low dunst"

  case $(dunstctl is-paused) in
  true)
    dunstctl set-paused false
    $notify "Notifications are enabled"
    ;;
  false)
    $notify "Notifications are pausing..."
    # the delay is here because pausing notifications immediately hides
    # the ones present on your desktop; we also run dunstctl close so
    # that the notification doesn't reappear on unpause
    (sleep 3 && dunstctl close && dunstctl set-paused true) &
    ;;
  esac
}

read() {
  case $(dunstctl is-paused) in
  true)
    echo "$DISABLED"
    ;;
  false)
    echo "$ENABLED"
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
