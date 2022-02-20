#!/usr/bin/env bash

case "$AUTORANDR_CURRENT_PROFILE" in
mbp | mbp-i)
  DPI=192
  CURSOR_SIZE=64
  GAP=25
  ;;
desktop-4k | mbp-4k | mbp-i-4k)
  DPI=144
  CURSOR_SIZE=48
  GAP=25
  ;;
*)
  DPI=96
  CURSOR_SIZE=32
  GAP=16
  ;;
esac

# Update Xft DPI for apps that don't use gnome settings daemon.
# Those apps will only get the new DPI when they restart.
echo "Xft.dpi: $DPI" | xrdb -merge

# Update cursor size
echo "Xcursor.size: $CURSOR_SIZE" | xrdb -merge
xsetroot -xcf /run/current-system/sw/share/icons/capitaine-cursors/cursors/left_ptr $CURSOR_SIZE
sed --follow-symlinks --in-place -E "/CursorThemeSize/s/[0-9.]+/$CURSOR_SIZE/" "$HOME/.config/xsettingsd/xsettingsd.conf"

# Update rofi dpi
sed --follow-symlinks --in-place -E "/dpi:/s/[0-9.]+/$DPI/" "$HOME/.config/rofi/config.rasi"

# Update spacing wm
bspc config window_gap "$GAP"

# Update Xft DPI in xsettingsd which is a lightweight gnome settings daemon implementation.
# The apps which query gsd for DPI will get updated on the fly.
sed --follow-symlinks --in-place -E "/DPI/s/[0-9.]+/$DPI/" "$HOME/.config/xsettingsd/xsettingsd.conf"
if [[ "$DPI" == "192" ]]; then
  sed --follow-symlinks --in-place -E "/WindowScalingFactor/s/[0-9.]+/2/" "$HOME/.config/xsettingsd/xsettingsd.conf"
  sed --follow-symlinks --in-place "/UnscaledDPI/c\Gdk\/UnscaledDPI 0" "$HOME/.config/xsettingsd/xsettingsd.conf"
else
  sed --follow-symlinks --in-place -E "/WindowScalingFactor/s/[0-9.]+/1/" "$HOME/.config/xsettingsd/xsettingsd.conf"
  sed --follow-symlinks --in-place "/UnscaledDPI/c\# Gdk\/UnscaledDPI 0" "$HOME/.config/xsettingsd/xsettingsd.conf"
fi
killall -HUP xsettingsd

/etc/scripts/dunst-start.sh &
/etc/scripts/polybar-start.sh &

