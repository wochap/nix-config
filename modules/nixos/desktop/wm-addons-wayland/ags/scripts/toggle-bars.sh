#!/usr/bin/env bash

wlr-randr --json | jq -c '.[]' | while read -r display; do
  monitorPlugName=$(echo "$display" | jq -r '.name')
  is_focused=$(dwl-state "$monitorPlugName" selmon --once | jq -r '.text')
  if [[ "$is_focused" == "1" ]]; then
    ags --toggle-window "bar-$monitorPlugName"
  fi
done
