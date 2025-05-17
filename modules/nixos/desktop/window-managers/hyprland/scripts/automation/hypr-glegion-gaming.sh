#!/usr/bin/env bash

output_name=$(wlr-randr --json | jq -r '.[] | select(.name | startswith("HEADLESS")) | .name | limit(1; .)')

cleanup() {
  echo "Cleaning up..."

  # remove hyprland headless output
  hyprctl output remove HEADLESS-1
  sleep 0.1

  # kill all subprocesses
  pkill -P $$
}

if [[ -z "$output_name" ]]; then
  # create hyprland headless output
  hyprctl output create headless HEADLESS-1
  sleep 0.1

  output_name=$(wlr-randr --json | jq -r '.[] | select(.name | startswith("HEADLESS")) | .name | limit(1; .)')
fi

# update scaling of HEADLESS output
kanshictl switch glegion-gaming &
sleep 0.1

# show bar on HEADLESS output
systemctl --user restart ags.service &

# show wallpaper on HEADLESS output
systemctl --user restart swww-daemon.service &

# show HEADLESS output in physical output
wl-mirror "$output_name" &

trap cleanup EXIT

# keep the script running
while true; do
  sleep 1
done
