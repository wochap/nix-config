#!/usr/bin/env bash

MONOCLE_DIR="/tmp"
MONOCLE_FILENAME="hyprland-monocle-$HYPRLAND_INSTANCE_SIGNATURE"
MONOCLE_FILEPATH="$MONOCLE_DIR/$MONOCLE_FILENAME"

# Checks if a given workspace is in monocle mode
function get_is_ws_monocle() {
  local ws_id="$1"

  if [[ -f "$MONOCLE_FILEPATH" ]] && grep -qxF "$ws_id" "$MONOCLE_FILEPATH"; then
    echo "true"
  else
    echo "false"
  fi
}

# Sets the monocle state for a given workspace
function set_is_ws_monocle() {
  local ws_id="$1"
  local is_monocle="$2"

  if [[ ! -f "$MONOCLE_FILEPATH" ]]; then
    touch "$MONOCLE_FILEPATH"
  fi

  if [[ "$is_monocle" == "true" ]]; then
    if ! grep -qxF "$ws_id" "$MONOCLE_FILEPATH"; then
      echo "$ws_id" >>"$MONOCLE_FILEPATH"
    fi
  else
    sed -i "/^$ws_id$/d" "$MONOCLE_FILEPATH"
  fi
}

# Handles new windows, moving them to a monocle group if necessary
function init_monocle() {
  function handle() {
    local input="$1"
    local event="${input%%>>*}"
    local payload="${input#*>>}"

    # Move window into group if its workspace is monocle and it is tiled
    if [[ "$event" == "openwindow" ]]; then
      local address ws app_id title
      IFS=',' read -r address ws app_id title <<<"$payload"
      local window_address="0x$address"
      local is_window_floating is_window_grouped focused_ws_id is_focused_ws_monocle windows_addresses
      is_window_floating=$(hyprctl clients -j | jq -r ".[] | select(.address == \"$window_address\") | .floating")
      is_window_grouped=$(hyprctl clients -j | jq -r ".[] | select(.address == \"$window_address\") | .grouped | length > 0")
      focused_ws_id=$(hyprctl activeworkspace -j | jq -cr '.id')
      is_focused_ws_monocle=$(get_is_ws_monocle "$focused_ws_id")
      windows_addresses=$(hyprctl -j clients | jq -cr ".[] | select(.workspace.id == $focused_ws_id and .floating == false and .hidden == false) | .address")

      if [[ "$is_window_floating" == "false" && "$is_window_grouped" == "false" ]]; then
        if [[ -z "$windows_addresses" ]]; then
          echo "no windows found"
        elif [[ "$(echo "$windows_addresses" | wc -l)" -eq 1 && "$is_focused_ws_monocle" == "true" ]]; then
          local batch_args="dispatch focusworkspaceoncurrentmonitor $focused_ws_id;"
          batch_args="$batch_args dispatch focuswindow address:$window_address; dispatch togglegroup;"
          batch_args="$batch_args dispatch focusworkspaceoncurrentmonitor $focused_ws_id;"
          hyprctl --batch "$batch_args"
        elif [[ "$(echo "$windows_addresses" | wc -l)" -gt 1 && "$is_focused_ws_monocle" == "true" ]]; then
          local batch_args="dispatch setignoregrouplock on;"
          batch_args="$batch_args dispatch focusworkspaceoncurrentmonitor $focused_ws_id;"
          batch_args="$batch_args dispatch focuswindow address:$window_address; dispatch togglegroup;"
          batch_args="$batch_args dispatch moveintogroup l; dispatch moveintogroup r; dispatch moveintogroup u; dispatch moveintogroup d;"
          batch_args="$batch_args dispatch setignoregrouplock off;"
          batch_args="$batch_args dispatch focusworkspaceoncurrentmonitor $focused_ws_id;"
          hyprctl --batch "$batch_args"
          echo "more than 1 window"
        fi
      fi
    fi
  }

  socat -U - "UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" | while read -r line; do handle "$line"; done
}

# Activates monocle mode for the focused workspace
function start_monocle() {
  local focused_window_address focused_ws_id windows_addresses first_window_address is_focused_ws_monocle
  focused_window_address="$(hyprctl -j activewindow | jq -cr '.address')"
  focused_ws_id=$(hyprctl activeworkspace -j | jq -cr '.id')
  windows_addresses=$(hyprctl -j clients | jq -cr ".[] | select(.workspace.id == $focused_ws_id and .floating == false) | .address")
  first_window_address=$(echo "$windows_addresses" | head -n 1)
  is_focused_ws_monocle=$(get_is_ws_monocle "$focused_ws_id")

  if [[ "$is_focused_ws_monocle" == "false" ]]; then
    set_is_ws_monocle "$focused_ws_id" "true"
  fi

  if [[ -z "$windows_addresses" ]]; then
    echo "no windows found"
  elif [[ "$(echo "$windows_addresses" | wc -l)" -eq 1 ]]; then
    # If there's just one window, just group it normally for better UX
    hyprctl --batch "dispatch focuswindow address:$first_window_address; dispatch togglegroup; dispatch focuswindow address:$focused_window_address;"
  elif [[ "$(echo "$windows_addresses" | wc -l)" -gt 1 ]]; then
    # Move to each window and try to group it every which way
    local window_args=""
    for window_address in $windows_addresses; do
      window_args="$window_args dispatch focuswindow address:$window_address; dispatch moveintogroup l; dispatch moveintogroup r; dispatch moveintogroup u; dispatch moveintogroup d;"
    done

    # Group the first window
    local batch_args="dispatch focuswindow address:$first_window_address; dispatch togglegroup;"

    # Group all other windows twice (once isn't enough in case of very
    # "deep" layouts". This ugly workaround could be fixed if hyprland
    # allowed moving into groups based on addresses and not positions
    batch_args="$batch_args $window_args $window_args"

    # Also focus the original window at the very end
    batch_args="$batch_args dispatch focuswindow address:$focused_window_address;"

    # Execute the grouping using hyprctl --batch for performance
    hyprctl --batch "$batch_args"
  fi
}

# Deactivates monocle mode for the focused workspace
function finish_monocle() {
  local focused_window_address focused_ws_id windows_addresses first_window_address is_focused_ws_monocle
  focused_window_address="$(hyprctl -j activewindow | jq -cr '.address')"
  focused_ws_id=$(hyprctl activeworkspace -j | jq -cr '.id')
  windows_addresses=$(hyprctl -j clients | jq -cr ".[] | select(.workspace.id == $focused_ws_id and .floating == false) | .address")
  first_window_address=$(echo "$windows_addresses" | head -n 1)
  is_focused_ws_monocle=$(get_is_ws_monocle "$focused_ws_id")

  if [[ "$is_focused_ws_monocle" == "false" ]]; then
    exit 0
  fi

  if [[ -z "$windows_addresses" ]]; then
    echo "no windows found"
  elif [[ "$(echo "$windows_addresses" | wc -l)" -gt 0 ]]; then
    # Ungroup and restore focus
    hyprctl --batch "dispatch focuswindow address:$first_window_address; dispatch togglegroup; dispatch focuswindow address:$focused_window_address;"
  fi

  set_is_ws_monocle "$focused_ws_id" "false"
}

# Moves the active window to a specified workspace
function move_to_workspace() {
  local ws_id="$1"
  local focused_ws_id is_focused_window_grouped is_focused_window_floating focused_window_address is_ws_monocle
  focused_ws_id=$(hyprctl activeworkspace -j | jq -cr '.id')
  is_focused_window_grouped=$(hyprctl activewindow -j | jq '.grouped | length > 0')
  is_focused_window_floating=$(hyprctl activewindow -j | jq -r '.floating')
  focused_window_address=$(hyprctl activewindow -j | jq -r '.address')
  is_ws_monocle=$(get_is_ws_monocle "$ws_id")

  if [[ "$is_focused_window_grouped" == "true" ]]; then
    hyprctl --batch "dispatch moveoutofgroup active; dispatch movetoworkspacesilent $ws_id;"
  else
    hyprctl dispatch movetoworkspacesilent "$ws_id"
  fi

  if [[ "$is_ws_monocle" == "true" && "$is_focused_window_floating" != "true" ]]; then
    local batch_args="dispatch setignoregrouplock on;"
    batch_args="$batch_args dispatch focuswindow address:$focused_window_address; dispatch togglegroup;"
    batch_args="$batch_args dispatch moveintogroup l; dispatch moveintogroup r; dispatch moveintogroup u; dispatch moveintogroup d;"
    batch_args="$batch_args dispatch setignoregrouplock off;"
    batch_args="$batch_args dispatch focusworkspaceoncurrentmonitor $focused_ws_id;"
    hyprctl --batch "$batch_args"
  fi
}

# Toggles the floating state of the active window
function toggle_floating() {
  local is_focused_window_grouped is_focused_window_floating focused_ws_id is_focused_ws_monocle
  is_focused_window_grouped=$(hyprctl activewindow -j | jq '.grouped | length > 0')
  is_focused_window_floating=$(hyprctl activewindow -j | jq -r '.floating')
  focused_ws_id=$(hyprctl activeworkspace -j | jq -cr '.id')
  is_focused_ws_monocle=$(get_is_ws_monocle "$focused_ws_id")

  if [[ "$is_focused_window_floating" == "true" ]]; then
    # Is floating, tile it
    if [[ "$is_focused_window_grouped" == "true" ]]; then
      hyprctl --batch "dispatch moveoutofgroup active; dispatch settiled active;"
    else
      hyprctl --batch "dispatch settiled active;"
    fi

    if [[ "$is_focused_ws_monocle" == "true" ]]; then
      local batch_args="dispatch setignoregrouplock on;"
      batch_args="$batch_args dispatch togglegroup;"
      batch_args="$batch_args dispatch moveintogroup l; dispatch moveintogroup r; dispatch moveintogroup u; dispatch moveintogroup d;"
      batch_args="$batch_args dispatch setignoregrouplock off;"
      hyprctl --batch "$batch_args"
    fi
  else
    # Is tiled, float it
    if [[ "$is_focused_window_grouped" == "true" ]]; then
      hyprctl --batch "dispatch moveoutofgroup active; dispatch setfloating active; dispatch centerwindow;"
    else
      hyprctl --batch "dispatch setfloating active; dispatch centerwindow;"
    fi
  fi
}

# Cycles focus between windows
function cycle() {
  local dir="$1"   # next|prev
  local scope="$2" # tiled|floating
  local is_focused_window_grouped is_focused_window_floating
  is_focused_window_grouped=$(hyprctl activewindow -j | jq '.grouped | length > 0')
  is_focused_window_floating=$(hyprctl activewindow -j | jq -r '.floating')

  if [[ "$scope" == "tiled" && "$is_focused_window_floating" == "true" ]]; then
    hyprctl dispatch cyclenext "$dir" "$scope"
    exit 0
  fi

  if [[ "$is_focused_window_grouped" == "true" ]]; then
    if [[ "$dir" == "next" ]]; then
      local is_last
      is_last=$(hyprctl activewindow -j | jq '. as $window | $window.grouped | length > 0 and .[-1] == $window.address')
      if [[ "$is_last" == "true" ]]; then
        local focused_ws_id focused_window_address others_windows_count
        focused_ws_id=$(hyprctl activeworkspace -j | jq -r '.name')
        focused_window_address=$(hyprctl activewindow -j | jq -r .address)
        if [[ "$scope" == "tiled" ]]; then
          others_windows_count=$(hyprctl clients -j | jq "[.[] | select(.workspace.name == \"$focused_ws_id\" and .hidden == false and .address != \"$focused_window_address\" and .floating == false)] | length")
        else
          others_windows_count=$(hyprctl clients -j | jq "[.[] | select(.workspace.name == \"$focused_ws_id\" and .hidden == false and .address != \"$focused_window_address\")] | length")
        fi

        if ((others_windows_count > 0)); then
          hyprctl dispatch cyclenext next "$scope"
        else
          hyprctl dispatch changegroupactive f
        fi
      else
        hyprctl dispatch changegroupactive f
      fi
    elif [[ "$dir" == "prev" ]]; then
      local is_first
      is_first=$(hyprctl activewindow -j | jq '. as $window | $window.grouped | length > 0 and .[0] == $window.address')
      if [[ "$is_first" == "true" ]]; then
        local focused_ws_id focused_window_address others_windows_count
        focused_ws_id=$(hyprctl activeworkspace -j | jq -r '.name')
        focused_window_address=$(hyprctl activewindow -j | jq -r .address)
        if [[ "$scope" == "tiled" ]]; then
          others_windows_count=$(hyprctl clients -j | jq "[.[] | select(.workspace.name == \"$focused_ws_id\" and .hidden == false and .address != \"$focused_window_address\" and .floating == false)] | length")
        else
          others_windows_count=$(hyprctl clients -j | jq "[.[] | select(.workspace.name == \"$focused_ws_id\" and .hidden == false and .address != \"$focused_window_address\")] | length")
        fi

        if ((others_windows_count > 0)); then
          hyprctl dispatch cyclenext prev "$scope"
        else
          hyprctl dispatch changegroupactive b
        fi
      else
        hyprctl dispatch changegroupactive b
      fi
    fi
  else
    if [[ "$dir" == "next" ]]; then
      hyprctl dispatch cyclenext next "$scope"
    elif [[ "$dir" == "prev" ]]; then
      hyprctl dispatch cyclenext prev "$scope"
    fi
  fi

  hyprctl dispatch alterzorder top
}

# Gets the status of monocle workspaces
function get_status() {
  local ws_ids=""

  # Check if the file exists, is a regular file, and is not empty
  if [[ -f "$MONOCLE_FILEPATH" && -s "$MONOCLE_FILEPATH" ]]; then
    ws_ids=$(paste -sd, "$MONOCLE_FILEPATH")
  fi

  echo "[$ws_ids]"
}

function listen() {
  get_status

  inotifywait -m -q -e close_write -e create -e moved_to "$MONOCLE_DIR" --format '%e %f' |
    while read -r event file; do
      if [[ "$file" == "$MONOCLE_FILENAME" ]]; then
        get_status
      fi
    done
}

# Main script logic: argument parsing
case "$1" in
--listen)
  listen
  ;;
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
  if [[ -z "$2" ]]; then
    echo "Error: --move-to-workspace requires a workspace ID argument."
    exit 1
  fi
  move_to_workspace "$2"
  ;;
--toggle-floating)
  toggle_floating
  ;;
--cycle)
  if [[ -z "$2" ]]; then
    echo "Error: --cycle requires a dir argument."
    exit 1
  fi
  cycle "$2" "$3"
  ;;
--status)
  get_status
  ;;
*)
  echo "Usage: $0 [--init | --start | --finish | --toggle-floating | --move-to-workspace <workspace_id> | --cycle <dir> <scope>]"
  exit 1
  ;;
esac
