#!/usr/bin/env sh

# get dpi
DPI=$(xrdb -query | grep dpi | sed "s/Xft.dpi://" | xargs)

killall dunst

case "$DPI" in
144)
  SCALE=1.5
  ;;
*)
  SCALE=1
  ;;
esac

# update dust scale in place
sed --follow-symlinks --in-place -E "/scale=/s/[0-9.]+/$SCALE/" "$HOME/.config/dunst/dunstrc"

dunst &

