#!/usr/bin/env bash

output_name=$(wlr-randr --json | jq -r '.[] | select(.name | startswith("HEADLESS")) | .name | limit(1; .)')

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

# update aspect ratio of HEADLESS output
kanshictl switch glegion-vnc &
sleep 0.1

# show bar on HEADLESS output
systemctl --user restart ags.service &

# show wallpaper on HEADLESS output
systemctl --user restart swww-daemon.service &

# on tty 1
wayvnc --output="eDP-1" --max-fps=60 0.0.0.0 5900

# on tty 2
# Hyprland --config ~/.config/hypr/vnc.conf
# remmina "$XDG_CONFIG_HOME/remmina/glegion.remmina" &
