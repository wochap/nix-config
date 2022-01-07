#!/usr/bin/env bash

# For custom Polybar module `bspwm_monocle_nb_windows`
_trigger_polybar_windows_number() {
  desktop_layout=$(bspc query -T -d|jq -r .layout)
  [[ $desktop_layout == "monocle" ]] && {
    (polybar-msg hook bspwm_monocle_nb_windows 1) &>/dev/null
    (polybar-msg hook bspwm_monocle_nb_windows_sep 1) &>/dev/null
    # TODO: hide polybar?
  } || {
    (polybar-msg hook bspwm_monocle_nb_windows 2) &>/dev/null
    (polybar-msg hook bspwm_monocle_nb_windows_sep 2) &>/dev/null
    # TODO: show polybar?
  }
}
while read -a line; do
	case "$line" in
    desktop_focus)
      _trigger_polybar_windows_number
      ;;
    desktop_layout)
      _trigger_polybar_windows_number
      ;;
    node_add)
      _trigger_polybar_windows_number
      ;;
    node_stack)
      _trigger_polybar_windows_number
      ;;
    node_remove)
      _trigger_polybar_windows_number
      ;;
	esac
done < <(bspc subscribe desktop_layout desktop_focus node_add node_remove node_stack node_focus)
