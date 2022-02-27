#!/usr/bin/env bash

rofi \
  -combi-modi drun \
  -modi combi,bin:/etc/scripts/rofi-custom-options.sh \
  -show combi \
  -show-icons \
  -theme-str 'listview { columns: 2; }' \
  -theme-str 'window { width: 40em; }'

