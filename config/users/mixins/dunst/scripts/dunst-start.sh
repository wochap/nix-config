#!/usr/bin/env sh

killall dunst

# get dpi
DPI=$(xrdb -query | grep dpi | sed "s/Xft.dpi://" | xargs)

case "$DPI" in
192)
  HEIGHT="300"
  HORIZONTAL_PADDING="22"
  PADDING="22"
  WIDTH="700"
  MAX_ICON_SIZE="96"
  MIN_ICON_SIZE="96"
  OFFSET="25"
  ;;
144)
  HEIGHT="225"
  HORIZONTAL_PADDING="17"
  PADDING="17"
  WIDTH="525"
  MAX_ICON_SIZE="72"
  MIN_ICON_SIZE="72"
  OFFSET=25
  ;;
*)
  HEIGHT="150"
  HORIZONTAL_PADDING="11"
  PADDING="11"
  WIDTH="350"
  MAX_ICON_SIZE="48"
  MIN_ICON_SIZE="48"
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
