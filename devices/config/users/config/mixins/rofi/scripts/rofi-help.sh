#!/usr/bin/env bash

awk '/^[a-z]/ && last {print "<span>"$0"\t",last,"</span>"} {last=""} /^#/{last=$0}' /etc/config/sxhkdrc |
  column -t -s $'\t' | \
  rofi \
    -window-title rofi-help \
    -dmenu \
    -i \
    -p  \
    -markup-rows \
    -theme /etc/config/rofi-help-theme.rasi \
    -plugin-path $ROFI_PLUGIN_PATH
