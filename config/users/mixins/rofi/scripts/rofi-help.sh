#!/usr/bin/env bash

# get dpi
DPI=$(xrdb -query | grep dpi | sed "s/Xft.dpi://" | xargs)

awk '/^[a-z]/ && last {print "<span>"$0"\t",last,"</span>"} {last=""} /^#/{last=$0}' /etc/config/sxhkdrc |
  column -t -s $'\t' | \
  rofi \
    -window-title rofi-help \
    -dmenu \
    -dpi "$DPI" \
    -p "help" \
    -markup-rows \
    -config "$HOME/.config/rofi/rofi-help-theme.rasi"
