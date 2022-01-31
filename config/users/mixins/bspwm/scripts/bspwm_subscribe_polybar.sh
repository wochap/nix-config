#!/usr/bin/env bash

# For custom Polybar module `bspwm_monocle_nb_windows`
_trigger_polybar_windows_number() {
  hidden_windows=$(bspc query -N -n .hidden.local.window | wc -l)
  [[ $hidden_windows -gt "0" ]] && {
    echo $hidden_windows
    echo "show"
    (polybar-msg hook bspwm_hidden_windows 1) &>/dev/null
    (polybar-msg hook bspwm_hidden_windows_sep 1) &>/dev/null
  } || {
    echo $hidden_windows
    echo "hide"
    (polybar-msg hook bspwm_hidden_windows 2) &>/dev/null
    (polybar-msg hook bspwm_hidden_windows_sep 2) &>/dev/null
  }

  desktop_layout=$(bspc query -T -d | jq -r .layout)
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
  *)
    _trigger_polybar_windows_number
    ;;
  esac
done < <(bspc subscribe desktop_layout desktop_focus node_add node_remove node_stack node_focus node_flag)
