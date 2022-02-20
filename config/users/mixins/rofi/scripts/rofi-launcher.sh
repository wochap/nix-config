#!/usr/bin/env bash

rofi \
  -combi-modi drun \
  -modi combi,bin:/etc/scripts/rofi-custom-options.sh \
  -show combi \
  -show-icons \
  -theme-str 'listview { columns: 3; }' \
  -theme-str 'window { width: 50em; }'

