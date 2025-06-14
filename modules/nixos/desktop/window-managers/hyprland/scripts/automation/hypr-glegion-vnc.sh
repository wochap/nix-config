#!/usr/bin/env bash

# e.g. eDP-1
output_name=$(wlr-randr --json | jq -r '.[] | select(.name | endswith("-1")) | .name | limit(1; .)')

cleanup() {
  echo "Cleaning up..."

  # kill all subprocesses
  pkill -P $$
}

# NOTE: if the output isn't headless
# the screen freezes after switching to different tty
wayvnc --output="$output_name" --max-fps=60 0.0.0.0 5900 &
echo "wayvnc server started"

trap cleanup EXIT

# keep the script running
while true; do
  sleep 1
done

# on tty 2
# Hyprland --config ~/.config/hypr/kiosk.conf
# remmina ~/.config/remmina/hypr-glegion.remmina
