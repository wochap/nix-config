#!/usr/bin/env bash

# source theme colors
source "$HOME/.config/scripts/theme-colors.sh"

function handle() {
  input="$1"
  event="${input%%>>*}"
  payload="${input#*>>}"

  # use different active border colors for when
  # there's only 1 tiling window or not
  if [[ "$event" == "activewindow" ]]; then
    active_border_color="${primary#\#}"
    active_border_color_single="${surface0#\#}"
    ws=$(hyprctl activeworkspace -j | jq -cr '.id')
    monitor=$(hyprctl activeworkspace -j | jq -r .monitorID)
    tiling_windows_count=$(hyprctl -j clients | jq "[.[] | select(.workspace.id == $ws and .floating == false and .monitor == $monitor and (.grouped | length == 0))] | length")

    if [ "$tiling_windows_count" -eq 1 ]; then
      hyprctl keyword "general:col.active_border" "rgb($active_border_color_single)"
    else
      hyprctl keyword "general:col.active_border" "rgb($active_border_color)"
    fi
  fi
}

socat -U - "UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" | while read -r line; do handle "$line"; done
