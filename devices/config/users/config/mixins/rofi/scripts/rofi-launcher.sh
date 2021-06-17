#!/usr/bin/env bash

rofi \
  -theme /etc/rofi-theme.rasi \
  -show drun \
  -modi drun,run,bin:/etc/rofi-update-gaps.sh \
  -plugin-path $ROFI_PLUGIN_PATH \
  -theme-str 'listview { columns: 2; lines: 15; }' \
  -theme-str 'prompt { font: "Iosevka 20"; margin: -10px 0 0 0; }' \
  -theme-str 'configuration { show-icons: true; }'
