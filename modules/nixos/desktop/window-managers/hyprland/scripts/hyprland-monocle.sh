#!/usr/bin/env bash

function start_monocle() {
  focused_window_address="$(hyprctl -j activewindow | jq -cr '.address')"
  current_ws=$(hyprctl activeworkspace -j | jq -cr '.id')
  windows=$(hyprctl -j clients | jq -cr ".[] | select(.workspace.id == $current_ws and .floating == false) | .address")
  first_window=$(echo "$windows" | head -n 1)

  monitor=$(hyprctl activeworkspace -j | jq -r .monitor)
  file="/tmp/hyprland-$monitor-monocle-ws"

  if [[ -f "$file" ]]; then
    if grep -qxF "$current_ws" "$file"; then
      exit 0
    fi
  fi

  # If there's just one window, just group it normally for better UX
  if [ "$(echo "$windows" | wc -l)" -eq 1 ]; then
    hyprctl --batch "dispatch focuswindow address:$first_window; dispatch togglegroup; dispatch focuswindow address:$focused_window_address;"
  else
    # Move to each window and try to group it every which way
    window_args=""
    for window in $windows; do
      window_args="$window_args dispatch focuswindow address:$window; dispatch moveintogroup l; dispatch moveintogroup r; dispatch moveintogroup u; dispatch moveintogroup d;"
    done

    # Group the first window
    batch_args="dispatch focuswindow address:$first_window; dispatch togglegroup;"

    # Group all other windows twice (once isn't enough in case of very
    # "deep" layouts". This ugly workaround could be fixed if hyprland
    # allowed moving into groups based on addresses and not positions
    batch_args="$batch_args $window_args $window_args"

    # Also focus the original window at the very end
    batch_args="$batch_args dispatch focuswindow address:$focused_window_address"

    # Execute the grouping using hyprctl --batch for performance
    hyprctl --batch "$batch_args"
  fi

  if ! grep -qxF "$current_ws" "$file"; then
    echo "$current_ws" >>"$file"
  fi
}

function finish_monocle() {
  focused_window_address="$(hyprctl -j activewindow | jq -cr '.address')"
  current_ws=$(hyprctl activeworkspace -j | jq -cr '.id')
  windows=$(hyprctl -j clients | jq -cr ".[] | select(.workspace.id == $current_ws and .floating == false) | .address")
  first_window=$(echo "$windows" | head -n 1)

  monitor=$(hyprctl activeworkspace -j | jq -r .monitor)
  file="/tmp/hyprland-$monitor-monocle-ws"

  if [[ -f "$file" ]]; then
    if ! grep -qxF "$current_ws" "$file"; then
      exit 0
    fi
  fi

  # ungroup and restore focus
  hyprctl --batch "dispatch focuswindow address:$first_window; dispatch togglegroup; dispatch focuswindow address:$focused_window_address;"

  if [[ -f "$file" ]]; then
    sed -i "/^$current_ws$/d" "$file"
  fi
}

function move_to_workspace() {
  current_ws=$(hyprctl activeworkspace -j | jq -cr '.id')
  ws="$1"
  is_focused_window_grouped=$(hyprctl activewindow -j | jq '.grouped | length > 0')
  is_ws_monocle="false"
  window_address=$(hyprctl activewindow -j | jq -r '.address')

  monitor=$(hyprctl activeworkspace -j | jq -r .monitor)
  file="/tmp/hyprland-$monitor-monocle-ws"

  if [[ -f "$file" ]]; then
    if grep -qxF "$ws" "$file"; then
      is_ws_monocle="true"
    fi
  fi

  if [ "$is_focused_window_grouped" = "true" ]; then
    hyprctl --batch "dispatch moveoutofgroup active; dispatch movetoworkspacesilent $ws"
  else
    hyprctl dispatch movetoworkspacesilent "$ws"
  fi

  if [ "$is_ws_monocle" = "true" ]; then
    batch_args="setignoregrouplock on;"
    batch_args="$batch_args dispatch focuswindow address:$window_address; dispatch togglegroup;"
    batch_args="$batch_args dispatch moveintogroup l; dispatch moveintogroup r; dispatch moveintogroup u; dispatch moveintogroup d;"
    batch_args="$batch_args setignoregrouplock off;"
    batch_args="$batch_args dispatch workspace $current_ws;"
    hyprctl --batch "$batch_args"
  fi
}

function toggle_floating() {
  is_focused_window_grouped=$(hyprctl activewindow -j | jq '.grouped | length > 0')
  is_floating=$(hyprctl activewindow -j | jq -r '.floating')

  current_ws=$(hyprctl activeworkspace -j | jq -cr '.id')
  monitor=$(hyprctl activeworkspace -j | jq -r .monitor)
  file="/tmp/hyprland-$monitor-monocle-ws"
  is_ws_monocle="false"
  if [[ -f "$file" ]]; then
    if grep -qxF "$current_ws" "$file"; then
      is_ws_monocle="true"
    fi
  fi

  if [ "$is_floating" = "true" ]; then
    # is floating, tile it
    if [ "$is_focused_window_grouped" = "true" ]; then
      hyprctl --batch "dispatch moveoutofgroup active; dispatch settiled active;"
    else
      hyprctl --batch "dispatch settiled active;"
    fi

    if [ "$is_ws_monocle" = "true" ]; then
      batch_args="setignoregrouplock on;"
      batch_args="$batch_args dispatch moveintogroup l; dispatch moveintogroup r; dispatch moveintogroup u; dispatch moveintogroup d;"
      batch_args="$batch_args setignoregrouplock off;"
      hyprctl --batch "$batch_args"
    fi
  else
    # is tiled, float it
    if [ "$is_focused_window_grouped" = "true" ]; then
      hyprctl --batch "dispatch moveoutofgroup active; dispatch setfloating active; dispatch centerwindow;"
    else
      hyprctl --batch "dispatch setfloating active; dispatch centerwindow;"
    fi
  fi
}

function cycle() {
  dir="$1"
  is_focused_window_grouped=$(hyprctl activewindow -j | jq '.grouped | length > 0')

  if [ "$is_focused_window_grouped" = "true" ]; then
    if [ "$dir" = "next" ]; then
      is_last=$(hyprctl activewindow -j | jq '. as $window | $window.grouped | length > 0 and .[-1] == $window.address')
      if [ "$is_last" = "true" ]; then
        current_ws=$(hyprctl activeworkspace -j | jq -r '.name')
        current_window_address=$(hyprctl activewindow -j | jq -r .address)
        others_windows_count=$(hyprctl clients -j | jq "[.[] | select(.workspace.name == \"$current_ws\" and .hidden == false and .address != \"$current_window_address\")] | length")

        if ((others_windows_count > 0)); then
          hyprctl dispatch cyclenext
        else
          hyprctl dispatch changegroupactive f
        fi
      else
        hyprctl dispatch changegroupactive f
      fi
    elif [ "$dir" = "prev" ]; then
      is_first=$(hyprctl activewindow -j | jq '. as $window | $window.grouped | length > 0 and .[0] == $window.address')
      if [ "$is_first" = "true" ]; then
        current_ws=$(hyprctl activeworkspace -j | jq -r '.name')
        current_window_address=$(hyprctl activewindow -j | jq -r .address)
        others_windows_count=$(hyprctl clients -j | jq "[.[] | select(.workspace.name == \"$current_ws\" and .hidden == false and .address != \"$current_window_address\")] | length")

        if ((others_windows_count > 0)); then
          hyprctl dispatch cyclenext prev
        else
          hyprctl dispatch changegroupactive b
        fi
      else
        hyprctl dispatch changegroupactive b
      fi
    fi
  else
    if [ "$dir" = "next" ]; then
      hyprctl dispatch cyclenext
    elif [ "$dir" = "prev" ]; then
      hyprctl dispatch cyclenext prev
    fi
  fi

  hyprctl dispatch alterzorder top
}

case "$1" in
--start)
  start_monocle
  ;;
--finish)
  finish_monocle
  ;;
--movetows)
  if [ -z "$2" ]; then
    echo "Error: --movetows requires a workspace ID argument."
    exit 1
  fi
  move_to_workspace "$2"
  ;;
--togglefloating)
  toggle_floating
  ;;
--cycle)
  if [ -z "$2" ]; then
    echo "Error: --cycle requires a dir argument."
    exit 1
  fi
  cycle "$2"
  ;;
*)
  echo "Usage: $0 [--start | --finish | togglefloating | --movetows <workspace_id> | --cycle <dir>]"
  exit 1
  ;;
esac
