#!/usr/bin/env bash

function get_is_monocle_ws() {
  local monitor="$1"
  local ws="$2"
  local file="/tmp/hyprland-$monitor-monocle-ws"

  if [[ -f "$file" ]] && grep -qxF "$ws" "$file"; then
    echo "true"
  else
    echo "false"
  fi
}

function init_monocle() {
  function handle() {
    input="$1"
    event="${input%%>>*}"
    payload="${input#*>>}"

    # move window into group if its workspace is monocle
    if [[ "$event" == "openwindow" ]]; then
      IFS=',' read -r address ws app_id title <<<"$payload"
      address="0x$address"
      current_ws=$(hyprctl activeworkspace -j | jq -cr '.id')
      monitor=$(hyprctl activeworkspace -j | jq -r .monitor)
      is_ws_monocle=$(get_is_monocle_ws "$monitor" "$ws")
      windows_addresses=$(hyprctl -j clients | jq -cr ".[] | select(.workspace.id == $ws and .floating == false) | .address")

      if [ "$(echo "$windows_addresses" | wc -l)" -eq 1 ] && [ "$is_ws_monocle" = "true" ]; then
        batch_args="dispatch workspace $ws;"
        batch_args="$batch_args dispatch focuswindow address:$address; dispatch togglegroup;"
        batch_args="$batch_args dispatch workspace $current_ws;"
        hyprctl --batch "$batch_args"
      fi
    fi
  }

  socat -U - "UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" | while read -r line; do handle "$line"; done
}

function start_monocle() {
  focused_window_address="$(hyprctl -j activewindow | jq -cr '.address')"
  current_ws=$(hyprctl activeworkspace -j | jq -cr '.id')
  windows_addresses=$(hyprctl -j clients | jq -cr ".[] | select(.workspace.id == $current_ws and .floating == false) | .address")
  first_window_address=$(echo "$windows_addresses" | head -n 1)
  monitor=$(hyprctl activeworkspace -j | jq -r .monitor)
  file="/tmp/hyprland-$monitor-monocle-ws"

  if [[ -f "$file" ]]; then
    if grep -qxF "$current_ws" "$file"; then
      exit 0
    fi
  fi

  if [ -z "$windows_addresses" ]; then
    echo "no windows found"
  elif [ "$(echo "$windows_addresses" | wc -l)" -eq 1 ]; then
    # If there's just one window, just group it normally for better UX
    hyprctl --batch "dispatch focuswindow address:$first_window_address; dispatch togglegroup; dispatch focuswindow address:$focused_window_address;"
  elif [ "$(echo "$windows_addresses" | wc -l)" -gt 1 ]; then
    # Move to each window and try to group it every which way
    window_args=""
    for window_address in $windows_addresses; do
      window_args="$window_args dispatch focuswindow address:$window_address; dispatch moveintogroup l; dispatch moveintogroup r; dispatch moveintogroup u; dispatch moveintogroup d;"
    done

    # Group the first window
    batch_args="dispatch focuswindow address:$first_window_address; dispatch togglegroup;"

    # Group all other windows twice (once isn't enough in case of very
    # "deep" layouts". This ugly workaround could be fixed if hyprland
    # allowed moving into groups based on addresses and not positions
    batch_args="$batch_args $window_args $window_args"

    # Also focus the original window at the very end
    batch_args="$batch_args dispatch focuswindow address:$focused_window_address;"

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
  windows_addresses=$(hyprctl -j clients | jq -cr ".[] | select(.workspace.id == $current_ws and .floating == false) | .address")
  first_window_address=$(echo "$windows_addresses" | head -n 1)
  monitor=$(hyprctl activeworkspace -j | jq -r .monitor)
  file="/tmp/hyprland-$monitor-monocle-ws"

  if [[ -f "$file" ]]; then
    if ! grep -qxF "$current_ws" "$file"; then
      exit 0
    fi
  fi

  if [ -z "$windows_addresses" ]; then
    echo "no windows found"
  elif [ "$(echo "$windows_addresses" | wc -l)" -gt 0 ]; then
    # ungroup and restore focus
    hyprctl --batch "dispatch focuswindow address:$first_window_address; dispatch togglegroup; dispatch focuswindow address:$focused_window_address;"
  fi

  if [[ -f "$file" ]]; then
    sed -i "/^$current_ws$/d" "$file"
  fi
}

function move_to_workspace() {
  ws="$1"
  monitor=$(hyprctl activeworkspace -j | jq -r .monitor)
  current_ws=$(hyprctl activeworkspace -j | jq -cr '.id')
  is_window_grouped=$(hyprctl activewindow -j | jq '.grouped | length > 0')
  is_window_floating=$(hyprctl activewindow -j | jq -r '.floating')
  window_address=$(hyprctl activewindow -j | jq -r '.address')
  is_ws_monocle=$(get_is_monocle_ws "$monitor" "$ws")

  if [ "$is_window_grouped" = "true" ]; then
    hyprctl --batch "dispatch moveoutofgroup active; dispatch movetoworkspacesilent $ws;"
  else
    hyprctl dispatch movetoworkspacesilent "$ws"
  fi

  if [ "$is_ws_monocle" = "true" ] && [ "$is_window_floating" != "true" ]; then
    batch_args="dispatch setignoregrouplock on;"
    batch_args="$batch_args dispatch focuswindow address:$window_address; dispatch togglegroup;"
    batch_args="$batch_args dispatch moveintogroup l; dispatch moveintogroup r; dispatch moveintogroup u; dispatch moveintogroup d;"
    batch_args="$batch_args dispatch setignoregrouplock off;"
    batch_args="$batch_args dispatch workspace $current_ws;"
    hyprctl --batch "$batch_args"
  fi
}

function toggle_floating() {
  is_window_grouped=$(hyprctl activewindow -j | jq '.grouped | length > 0')
  is_window_floating=$(hyprctl activewindow -j | jq -r '.floating')
  current_ws=$(hyprctl activeworkspace -j | jq -cr '.id')
  monitor=$(hyprctl activeworkspace -j | jq -r .monitor)
  is_ws_monocle=$(get_is_monocle_ws "$monitor" "$current_ws")

  if [ "$is_window_floating" = "true" ]; then
    # is floating, tile it
    if [ "$is_window_grouped" = "true" ]; then
      hyprctl --batch "dispatch moveoutofgroup active; dispatch settiled active;"
    else
      hyprctl --batch "dispatch settiled active;"
    fi

    if [ "$is_ws_monocle" = "true" ]; then
      batch_args="dispatch setignoregrouplock on;"
      batch_args="$batch_args dispatch togglegroup;"
      batch_args="$batch_args dispatch moveintogroup l; dispatch moveintogroup r; dispatch moveintogroup u; dispatch moveintogroup d;"
      batch_args="$batch_args dispatch setignoregrouplock off;"
      hyprctl --batch "$batch_args"
    fi
  else
    # is tiled, float it
    if [ "$is_window_grouped" = "true" ]; then
      hyprctl --batch "dispatch moveoutofgroup active; dispatch setfloating active; dispatch centerwindow;"
    else
      hyprctl --batch "dispatch setfloating active; dispatch centerwindow;"
    fi
  fi
}

function cycle() {
  dir="$1"
  is_window_grouped=$(hyprctl activewindow -j | jq '.grouped | length > 0')

  if [ "$is_window_grouped" = "true" ]; then
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
--init)
  init_monocle
  ;;
--start)
  start_monocle
  ;;
--finish)
  finish_monocle
  ;;
--move-to-workspace)
  if [ -z "$2" ]; then
    echo "Error: --movetows requires a workspace ID argument."
    exit 1
  fi
  move_to_workspace "$2"
  ;;
--toggle-floating)
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
  echo "Usage: $0 [--init | --start | --finish | togglefloating | --movetows <workspace_id> | --cycle <dir>]"
  exit 1
  ;;
esac
