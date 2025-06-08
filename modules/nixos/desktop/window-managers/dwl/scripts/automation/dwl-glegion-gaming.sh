#!/usr/bin/env bash

output_name=$(wlr-randr --json | jq -r '.[] | select(.name | startswith("HEADLESS")) | .name | limit(1; .)')

cleanup() {
  echo "Cleaning up..."
  # kill all subprocesses
  pkill -P $$

  # TODO: remove HEADLESS output?
}

if [[ -z "$output_name" ]]; then
  # initialize DWL headless output
  # 125 = logo
  # 56 = alt
  # 29 = ctrl
  # 54 = shift
  # 50 = m
  ydotool key 125:1 56:1 29:1 54:1 50:1 50:0 54:0 29:0 56:0 125:0
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
wl-mirror $output_name &

trap cleanup EXIT

# keep the script running
while true; do
  sleep 1
done
