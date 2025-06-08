#!/usr/bin/env bash

output_name="HEADLESS-2"
has_output=$(wlr-randr --json | jq -e ".[] | select(.name == \"$output_name\")" >/dev/null && echo true || echo false)

cleanup() {
  echo "Cleaning up..."

  # remove hyprland headless output
  hyprctl output remove "$output_name"
  sleep 0.1

  # kill all subprocesses
  pkill -P $$
}

if [[ "$has_output" == "false" ]]; then
  # create hyprland headless output
  hyprctl output create headless "$output_name"
  sleep 0.1
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
