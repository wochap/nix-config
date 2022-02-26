#!/usr/bin/env bash

# source theme colors
. "/etc/config/bspwm-colors.sh"

nprimary=$(echo $primary | sed "s/#//")
nbackground=$(echo $background | sed "s/#//")
nselection=$(echo $selection | sed "s/#//")

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

  case "$wm_class" in
  Brave-browser | Google-chrome | Firefox)
    if [[ $w_border_size -ne 2 ]]; then
      bspc config --node "$2" border_width 2
    fi
    ;;
  *)
    if [[ $w_border_size -ne 20 ]]; then
      bspc config --node "$2" border_width 20
    fi
    ;;
  esac

  case "${1:-focused}" in
  focused)
    case "$wm_class" in
    Brave-browser | Google-chrome | Firefox)
      # HACK: don't use bspc to change colors, that would affect all windows
      # NOTE: updating border size with chwb will cause infinite recursion
      chwb -c "0xff$nprimary" "$2"
      ;;
    *)
      chwbn -b 8 -c "0xff$nbackground" -c "0xff$nprimary" -b 2 -c "0xff$nbackground" -b 8 "$2"
      ;;
    esac
    ;;
  normal)
    case "$wm_class" in
    Brave-browser | Google-chrome | Firefox)
      chwb -c "0xff$nbackground" "$2"
      ;;
    *)
      chwbn -b 8 -c "0xff$nbackground" -c "0xff$nselection" -b 2 -c "0xff$nbackground" -b 8 "$2"
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
