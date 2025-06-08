#!/usr/bin/env bash

wlr-randr --json | jq -c '.[]' | while read -r display; do
  monitor_name=$(echo "$display" | jq -r '.name')
  if [[ "$XDG_SESSION_DESKTOP" == 'Hyprland' ]]; then
    current_monitor_name=$(hyprctl activeworkspace -j | jq -r ".monitor")
    is_focused=$([[ "$monitor_name" == "$current_monitor_name" ]] && echo "1" || echo "0")
  elif [[ "$XDG_SESSION_DESKTOP" == 'dwl' ]]; then
    is_focused=$(dwl-state "$monitor_name" selmon --once | jq -r '.text')
  fi
  if [[ "$is_focused" == "1" ]]; then
    ags --bus-name "$XDG_SESSION_DESKTOP" --toggle-window "bar-$monitor_name"
  fi
done
