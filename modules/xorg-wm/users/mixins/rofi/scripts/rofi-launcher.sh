#!/usr/bin/env bash

rofi \
  -show drun \
  -modi drun,bin:/etc/scripts/rofi-custom-options.sh \
  -theme-str 'listview { columns: 2; }' \
  -theme-str 'window { width: 40em; }'

