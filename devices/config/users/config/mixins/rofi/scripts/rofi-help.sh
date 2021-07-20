#!/usr/bin/env bash

awk '/^[a-z]/ && last {print "<span>",$0,"\t",last,"</span>"} {last=""} /^#/{last=$0}' /etc/config/sxhkdrc |
  column -t -s $'\t' | \
  rofi \
    -dmenu \
    -i \
    -markup-rows \
    -theme /etc/rofi-theme.rasi \
    -plugin-path $ROFI_PLUGIN_PATH \
    -theme-str 'window { width: 35em; }' \
    -theme-str 'listview { lines: 15; }'
