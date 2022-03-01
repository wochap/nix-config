#!/usr/bin/env sh

killall dunst

# get dpi
DPI=$(xrdb -query | grep dpi | sed "s/Xft.dpi://" | xargs)

case "$DPI" in
192)
  HEIGHT="300"
  HORIZONTAL_PADDING="40"
  PADDING="40"
  WIDTH="700"
  MAX_ICON_SIZE="120"
  MIN_ICON_SIZE="120"
  OFFSET="25"
  ;;
144)
  HEIGHT="225"
  HORIZONTAL_PADDING="30"
  PADDING="30"
  WIDTH="525"
  MAX_ICON_SIZE="90"
  MIN_ICON_SIZE="90"
  OFFSET=25
  ;;
*)
  HEIGHT="150"
  HORIZONTAL_PADDING="20"
  PADDING="20"
  WIDTH="350"
  MAX_ICON_SIZE="60"
  MIN_ICON_SIZE="60"
  OFFSET=16
  ;;
esac

# update dust scale in place
sed --follow-symlinks --in-place -E "/^height=/s/[0-9.]+/$HEIGHT/" "$HOME/.config/dunst/dunstrc"
sed --follow-symlinks --in-place -E "/^horizontal_padding=/s/[0-9.]+/$HORIZONTAL_PADDING/" "$HOME/.config/dunst/dunstrc"
sed --follow-symlinks --in-place -E "/^padding=/s/[0-9.]+/$PADDING/" "$HOME/.config/dunst/dunstrc"
sed --follow-symlinks --in-place -E "/^width=/s/[0-9.]+/$WIDTH/" "$HOME/.config/dunst/dunstrc"
sed --follow-symlinks --in-place -E "/^max_icon_size=/s/[0-9.]+/$MAX_ICON_SIZE/" "$HOME/.config/dunst/dunstrc"
sed --follow-symlinks --in-place -E "/^min_icon_size=/s/[0-9.]+/$MIN_ICON_SIZE/" "$HOME/.config/dunst/dunstrc"
sed --follow-symlinks --in-place -E "/^offset=/s/[0-9.]+/$OFFSET/g" "$HOME/.config/dunst/dunstrc"

dunst &
