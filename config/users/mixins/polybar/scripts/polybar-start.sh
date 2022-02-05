#!/usr/bin/env sh

killall polybar

# get dpi
DPI=$(xrdb -query | grep dpi | sed "s/Xft.dpi://" | xargs)

height="40"
font0="Iosevka Nerd Font:weight=Medium:size=12;3"
font1="woos:size=12;3"

case "$DPI" in
144 | 192)
  font0="Iosevka Nerd Font:weight=Medium:size=12;5"
  font1="woos:size=12;5"
  height="60"
  ;;
esac

for monitor in $(xrandr --query | grep " connected" | cut -d" " -f1); do
  MONITOR="$monitor" DPI="$DPI" HEIGHT="$height" FONT0="$font0" FONT1="$font1" polybar main -c "$HOME/.config/polybar/blocks.ini" -r &
done

