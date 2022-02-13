#!/usr/bin/env bash

case "$AUTORANDR_CURRENT_PROFILE" in
mbp | mbp-i)
  DPI=192
  ;;
desktop-4k | mbp-i-4k)
  DPI=144
  ;;
desktop-1080p)
  DPI=96
  ;;
*)
  echo "Unknown profile: $AUTORANDR_CURRENT_PROFILE"
  DPI=96
  ;;
esac

# Update Xft DPI for apps that don't use gnome settings daemon.
# Those apps will only get the new DPI when they restart.
echo "Xft.dpi: $DPI" | xrdb -merge

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

/etc/scripts/polybar-start.sh &
/etc/scripts/dunst-start.sh &

