#!/usr/bin/env bash

ENABLED=
DISABLED=

reload_waybar() {
  pkill -SIGRTMIN+8 waybar
}

toggle() {
  notify="notify-send --urgency=low --replace-id=696 dunst"

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
  count=$(dunstctl count history)
  count_str=$([[ $count -gt 0 ]] && echo " $count" || echo "")

  case $(dunstctl is-paused) in
  true)
    printf '{ "text": "<span rise=\\"-1000\\">%s</span>%s", "class": "disabled" }' "$DISABLED" "$count_str"
    ;;
  false)
    printf '{ "text": "<span rise=\\"-1000\\">%s</span>%s", "class": "enabled" }' "$ENABLED" "$count_str"
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
