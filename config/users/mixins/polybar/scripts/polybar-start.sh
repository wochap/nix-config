#!/usr/bin/env sh

killall polybar

# get dpi
DPI=$(xrdb -query | grep dpi | sed "s/Xft.dpi://" | xargs)

gap="16"
height="40"
font0="Iosevka Nerd Font:weight=Medium:size=12;3"
font1="woos:size=12;3"

case "$DPI" in
192)
  font0="Iosevka Nerd Font:weight=Medium:size=12;7"
  font1="woos:size=12;7"
  height="80"
  gap="25"
  ;;
144)
  font0="Iosevka Nerd Font:weight=Medium:size=12;5"
  font1="woos:size=12;5"
  height="60"
  gap="25"
  ;;
esac

for monitor in $(xrandr --query | grep " connected" | cut -d" " -f1); do
  MONITOR="$monitor" DPI="$DPI" HEIGHT="$height" GAP="$gap" FONT0="$font0" FONT1="$font1" polybar main -c "$HOME/.config/polybar/blocks.ini" -r &
done

