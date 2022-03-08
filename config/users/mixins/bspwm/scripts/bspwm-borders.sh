#!/usr/bin/env bash

# source theme colors
. "/etc/config/bspwm-colors.sh"

nprimary=$(echo $primary | sed "s/#//")
nbackground=$(echo $background | sed "s/#//")
nselection=$(echo $selection | sed "s/#//")

# Border sizes per dpi
DPI=$(xrdb -query | grep dpi | sed "s/Xft.dpi://" | xargs)
case "$DPI" in
192)
  border_hl_width="4"
  border_nhl_width="36"
  ;;
144)
  border_hl_width="3"
  border_nhl_width="27"
  ;;
*)
  border_hl_width="2"
  border_nhl_width="18"
  ;;
esac
border_width=$(echo "$border_nhl_width+$border_hl_width" | bc)

bsp_windows() {
  case "${1:-active}" in
  active)
    bspc query -N -n .local.descendant_of.window.leaf.!fullscreen
    ;;
  inactive)
    bspc query -N -n .local.!descendant_of.window.leaf.!fullscreen
    ;;
  esac
}

draw_border() {
  echo "draw_border $2"

  wm_class=$(xprop -id "$2" WM_CLASS | awk '{print $4}' | sed -e 's/^"//' -e 's/"$//')
  w_border_size=$(bspc config --node "$2" border_width)

  # Update window border size one time
  case "$wm_class" in
  Brave-browser | Google-chrome | Firefox | Zathura)
    if [[ $w_border_size -ne $border_hl_width ]]; then
      bspc config --node "$2" border_width "$border_hl_width"
    fi
    ;;
  *)
    if [[ $w_border_size -ne $border_nhl_width ]]; then
      bspc config --node "$2" border_width "$border_width"
    fi
    ;;
  esac

  case "${1:-focused}" in
  focused)
    case "$wm_class" in
    Brave-browser | Google-chrome | Firefox | Zathura)
      # HACK: don't use bspc to change colors, that would affect all windows
      # NOTE: updating border size with chwb will cause infinite recursion
      chwb -c "0xff$nprimary" "$2"
      ;;
    *)
      bg="$nbackground"

      # case "$wm_class" in
      # robo3t)
      #   bg="EFEBE7"
      #   ;;
      # esac

      # chwbn -b "$border_hl_width" -c "0xff$nprimary" -b "$border_hl_width" -c "0xff$bg" -b "$border_hl_width" -c "0xff$nprimary" -b 21 -c "0xff$bg" "$2"
      chwbn -b "$border_hl_width" -c "0xff$nprimary" -b "$border_nhl_width" -c "0xff$bg" "$2"
      # chwbn -b 8 -c "0xff$nbackground" -b 2 -c "0xff$nprimary" -b 8 -c "0xff$nbackground" "$2"
      ;;
    esac
    ;;
  normal)
    case "$wm_class" in
    Brave-browser | Google-chrome | Firefox | Zathura)
      chwb -c "0xff$nbackground" "$2"
      ;;
    *)
      bg="$nbackground"

      # case "$wm_class" in
      # robo3t)
      #   bg="EFEBE7"
      #   ;;
      # esac

      # chwbn -b "$border_hl_width" -c "0xff$nselection" -b "$border_hl_width" -c "0xff$bg" -b "$border_hl_width" -c "0xff$nselection" -b 21 -c "0xff$bg" "$2"
      chwbn -b "$border_hl_width" -c "0xff$nselection" -b "$border_nhl_width" -c "0xff$bg" "$2"
      # chwbn -b 8 -c "0xff$nbackground" -b 2 -c "0xff$nselection" -b 8 -c "0xff$nbackground" "$2"
      ;;
    esac
    ;;
  esac
}

_chwb2() {
  colorType=$1
  shift

  while [[ -n "$1" ]]; do
    draw_border "$colorType" "$1"
    shift
  done
}

# HACK: hide flashing
bspc config border_width "$border_width"
bspc config focused_border_color "$background"
bspc config normal_border_color "$background"

bspc subscribe node_state node_geometry node_focus | while read type _ _ node _; do
  # TODO: prevent infinite recursion
  if [[ $type == "node_geometry" ]]; then
    if [[ $(pfw) == "${node,,}" ]]; then
      _chwb2 focused "$node"
    else
      _chwb2 normal "$node"
    fi
  else
    _chwb2 focused $(bsp_windows)
    _chwb2 normal $(bsp_windows inactive)
    # TODO: update border of active windows?
  fi
done
