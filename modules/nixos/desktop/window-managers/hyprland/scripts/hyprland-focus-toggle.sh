#!/usr/bin/env bash

PROG=$(basename $0)
TEMP=$(getopt --options h --longoptions help -- "$@") || exit 1
eval set -- "$TEMP"

for i in "$@"; do
  case "$i" in
  -h | --help)
    echo "$PROG: class='$class' runstr='$runstr'" >&2
    exit 0
    ;;
  esac
done

shift
class="$1"
runstr="$2"

current_ws="$(hyprctl monitors -j | jq '.[] | select(.focused==true)' | jq -j '.activeWorkspace.name')"
if [[ -z "$current_ws" ]]; then
  notify-send "hyprland-focus-toggle" "Some Error Occured while getting current workspace."
  exit 1
fi

program_data=$(hyprctl clients -j | jq ".[] | select(.class == \"$class\")")
if [[ "$program_data" ]]; then
  focused=$(echo "$program_data" | jq '.focusHistoryID == 0')
  ws=$(echo "$program_data" | jq -j ".workspace.name")
  visible=$([ "$ws" == "$current_ws" ] && echo "true" || echo "false")
  if [[ "$visible" == "true" ]]; then
    if [[ "$focused" == "true" ]]; then
      hyprctl dispatch movetoworkspacesilent "special:scratchpads,^($class)$" &>/dev/null
      # TODO: focus next window on current workspace?
    else
      hyprctl dispatch focuswindow "^($class)$" &>/dev/null
    fi
  else
    hyprctl dispatch movetoworkspacesilent "e+0,^($class)$" &>/dev/null
    hyprctl dispatch focuswindow "^($class)$" &>/dev/null
  fi
else
  if [[ "$runstr" ]]; then
    hyprctl dispatch exec "$runstr"
  fi
fi

state_path="/tmp/hyprland-focus-toggle-state"

# save scratchpad class
if ! grep -qF "$class" "$state_path"; then
  echo "$class" >>"$state_path"
fi

# hide all others scratchpads
if [ -f "$state_path" ]; then
  while IFS= read -r line; do
    if [[ "$line" != "$class" ]]; then
      hyprctl dispatch movetoworkspacesilent "special:scratchpads,^($line)$" &>/dev/null
    fi
  done <"$state_path"
fi
