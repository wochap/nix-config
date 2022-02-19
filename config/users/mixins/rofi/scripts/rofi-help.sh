#!/usr/bin/env bash

awk '/^[a-z]/ && last {print "<span>"$0"\t",last,"</span>"} {last=""} /^#/{last=$0}' /etc/config/sxhkdrc |
  column -t -s $'\t' | \
  rofi \
    -window-title rofi-help \
    -dmenu \
    -i \
    -p "help" \
    -markup-rows \
    -config "$HOME/.config/rofi/rofi-help-theme.rasi"
