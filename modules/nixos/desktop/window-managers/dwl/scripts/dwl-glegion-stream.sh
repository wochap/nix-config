#!/usr/bin/env bash

output_name="HEADLESS-1"

if ! [[ $(wlr-randr | grep "$output_name") ]]; then
  # initialize DWL headless output
  # 125 = logo
  # 56 = alt
  # 29 = ctrl
  # 54 = shift
  # 50 = m
  ydotool key 125:1 56:1 29:1 54:1 50:1 50:0 54:0 29:0 56:0 125:0
  sleep 0.1
fi

kanshi &
sleep 0.1

if [[ $(pgrep -x "wayvnc" > /dev/null) ]]; then
  killall wayvnc
fi
wayvnc --output="$output_name" --max-fps=120 0.0.0.0 5900 &
sleep 0.1

remmina "$XDG_CONFIG_HOME/remmina/glegion.remmina" &
sleep 0.1

systemctl --user restart ags.service &
systemctl --user restart swww-daemon.service &

nvidia-offload obs

