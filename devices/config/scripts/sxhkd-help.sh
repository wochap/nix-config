#!/usr/bin/env bash

awk '/^[a-z]/ && last {print "<small>",$0,"\t",last,"</small>"} {last=""} /^#/{last=$0}' /etc/sxhkdrc |
  column -t -s $'\t' |
  rofi -dmenu -i -markup-rows -no-show-icons -theme /home/gean/.config/rofi-theme.rasi -width 1200 -lines 15 -yoffset 40
