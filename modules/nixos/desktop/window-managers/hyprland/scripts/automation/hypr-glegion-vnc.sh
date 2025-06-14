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

# update aspect ratio of HEADLESS output
kanshictl switch glegion-vnc &
sleep 0.1

# show HEADLESS output in physical output
wl-mirror "$output_name" &

# NOTE: if the output isn't headless
# the screen freezes after switching to tty2
wayvnc --output="$output_name" --max-fps=60 0.0.0.0 5900 &
echo "wayvnc server started"

trap cleanup EXIT

# keep the script running
while true; do
  sleep 1
done

# on tty 2
# Hyprland --config ~/.config/hypr/hyprland-vnc.conf
