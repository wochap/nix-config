#!/usr/bin/env bash

FILE="$HOME/tmp/offlinemsmtp-sendmail"
DIR="$(dirname "$FILE")"
FILENAME="$(basename "$FILE")"

reload_waybar() {
  pkill -SIGRTMIN+8 waybar
}

toggle() {
  notify="notify-send --urgency=low --replace-id=694 offlinemsmtp"

  if test -f "$FILE"; then
    rm "$FILE"
    $notify "Offlinemsmtp is disabled"
    reload_waybar
  else
    mkdir -p "$DIR"
    touch "$FILE"
    $notify "Offlinemsmtp is enabled"
    reload_waybar
  fi
}

print_status() {
  if test -f "$FILE"; then
    printf -- 'true\n'
  else
    printf -- 'false\n'
  fi
}

listen_status() {
  mkdir -p "$DIR"
  print_status

  inotifywait -m -e create -e delete "$DIR" 2>/dev/null | while read -r target_dir action event_file; do
    if [[ "$event_file" == "$FILENAME" ]]; then
      print_status
    fi
  done
}

if [[ "$1" == "--toggle" ]]; then
  toggle
elif [[ "$1" == "--status" ]]; then
  print_status
elif [[ "$1" == "--listen" ]]; then
  listen_status
else
  echo -e "Available Options : --toggle --status --listen"
fi
