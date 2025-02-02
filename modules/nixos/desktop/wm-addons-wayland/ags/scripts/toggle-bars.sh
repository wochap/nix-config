#!/usr/bin/env bash

wlr-randr --json | jq -c '.[]' | while read -r display; do
  monitor_plug_name=$(echo "$display" | jq -r '.name')
  is_focused=$(dwl-state "$monitor_plug_name" selmon --once | jq -r '.text')
  if [[ "$is_focused" == "1" ]]; then
    ags --bus-name "$XDG_SESSION_DESKTOP" --toggle-window "bar-$monitor_plug_name"
  fi
done
