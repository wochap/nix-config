#!/usr/bin/env bash

rofi \
  -theme /etc/config/rofi-launcher-theme.rasi \
  -combi-modi drun,run \
  -modi combi,bin:/etc/scripts/rofi-custom-options.sh \
  -show combi \
  -plugin-path $ROFI_PLUGIN_PATH
