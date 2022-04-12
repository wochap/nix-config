#!/usr/bin/env bash

case "$AUTORANDR_CURRENT_PROFILE" in
mbp | mbp-i)
  # Common values are 96, 120 (25% higher), 144 (50% higher), 168 (75% higher), 192 (100% higher)
  DPI=192
  CURSOR_SIZE=64
  GAP=0
  BORDER_WIDTH=4
  WINDOW_PADDING=40
  ;;
desktop-4k | mbp-4k | mbp-i-4k)
  DPI=144
  CURSOR_SIZE=48
  GAP=0
  BORDER_WIDTH=3
  WINDOW_PADDING=30
  ;;
*)
  DPI=96
  CURSOR_SIZE=32
  GAP=0
  BORDER_WIDTH=2
  WINDOW_PADDING=20
  ;;
esac
WINDOW_PADDING=$(echo "$WINDOW_PADDING-$BORDER_WIDTH" | bc)

# Update Xft DPI for apps that don't use gnome settings daemon.
# Those apps will only get the new DPI when they restart.
echo "Xft.dpi: $DPI" | xrdb -merge

# Update cursor size
echo "Xcursor.size: $CURSOR_SIZE" | xrdb -merge
xsetroot -xcf /run/current-system/sw/share/icons/capitaine-cursors/cursors/left_ptr $CURSOR_SIZE
sed --follow-symlinks --in-place -E "/CursorThemeSize/s/[0-9.]+/$CURSOR_SIZE/" "$HOME/.config/xsettingsd/xsettingsd.conf"

# Update rofi
sed --follow-symlinks --in-place -E "/dpi:/s/[0-9.]+/$DPI/" "$HOME/.config/rofi/config.rasi"
sed --follow-symlinks --in-place -E "/var-window-border-width:/s/[0-9.]+/$BORDER_WIDTH/" "$HOME/.config/rofi/config.rasi"
sed --follow-symlinks --in-place -E "/var-inputbar-padding:/s/[0-9.]+/$WINDOW_PADDING/" "$HOME/.config/rofi/config.rasi"
sed --follow-symlinks --in-place "/var-listview-padding:/c\  var-listview-padding: 0 $WINDOW_PADDING\px $WINDOW_PADDING\px;" "$HOME/.config/rofi/config.rasi"

# Update picom
sed --follow-symlinks --in-place -E "/shadow-offset-x/s/[0-9.]+/$WINDOW_PADDING/" "$HOME/.config/picom/picom.conf"
sed --follow-symlinks --in-place -E "/shadow-offset-y/s/[0-9.]+/$WINDOW_PADDING/" "$HOME/.config/picom/picom.conf"

# Update kitty inner border
sed --follow-symlinks --in-place -E "/window_border_width/s/[0-9.]+/$BORDER_WIDTH/" "$HOME/.config/kitty/common.conf"

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
  sed --follow-symlinks --in-place "/UnscaledDPI/c\Gdk\/UnscaledDPI \"-1\"" "$HOME/.config/xsettingsd/xsettingsd.conf"
fi
killall -HUP xsettingsd

/etc/scripts/dunst-start.sh >/dev/null 2>&1
/etc/scripts/polybar-start.sh >/dev/null 2>&1

pgrep -f bspwm-borders | xargs kill -9
/etc/scripts/bspwm-borders.sh >/dev/null 2>&1

# Move windows from inactive monitor to primary monitor
# TODO: this only works on single monitor setup
monitors=$(bspc query --monitors --names)
primary_monitor=$(bspc query --monitors --monitor primary --names)
normal_monitors=(${monitors[@]/"$primary_monitor"/})
for monitor in $normal_monitors; do
  /etc/scripts/bspwm-move-monitors-nodes.sh "$monitor" "$primary_monitor" &
done

# TODO: ask with rofi if is all good
