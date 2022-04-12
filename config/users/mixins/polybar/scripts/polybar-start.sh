#!/usr/bin/env sh

killall polybar

# get dpi
DPI=$(xrdb -query | grep dpi | sed "s/Xft.dpi://" | xargs)

gap="16"
height="30"
font0="Iosevka Nerd Font:weight=Medium:size=10;3"
font1="woos:size=10;3"

case "$DPI" in
192)
  font0="Iosevka Nerd Font:weight=Medium:size=10;7"
  font1="woos:size=10;7"
  height="60"
  gap="32"
  ;;
144)
  font0="Iosevka Nerd Font:weight=Medium:size=10;5"
  font1="woos:size=10;5"
  height="45"
  gap="24"
  ;;
esac

for monitor in $(bspc query --monitors --monitor primary --names); do
  MONITOR="$monitor" DPI="$DPI" HEIGHT="$height" GAP="$gap" FONT0="$font0" FONT1="$font1" polybar main -c "$HOME/.config/polybar/blocks.ini" -r &
done

