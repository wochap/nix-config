#!/usr/bin/env sh

killall dunst
killall .dunst-wrapped

# get dpi
DPI=$(xrdb -query | grep dpi | sed "s/Xft.dpi://" | xargs)

case "$DPI" in
192)
  SCALE=2
  FONT_SIZE=28
  ;;
*)
  SCALE=1
  FONT_SIZE=14
  ;;
esac

# update dust scale in place
sed --follow-symlinks --in-place -E "/^scale=/s/[0-9.]+/$SCALE/" "$HOME/.config/dunst/dunstrc"
sed --follow-symlinks --in-place -E "/^font=\"Iosevka Nerd Font /s/[0-9.]+/$FONT_SIZE/" "$HOME/.config/dunst/dunstrc"

dunst &
