#!/usr/bin/env bash

PROG=$(basename "$0")
TEMP=$(getopt --options h --longoptions help,raise-or-run-uwsm:,raise-or-run:,focus-last,toggle,toggle-in -- "$@") || exit 1
eval set -- "$TEMP"

current_ws="$(hyprctl activeworkspace -j | jq -r '.id')"
current_monitor="$(hyprctl activeworkspace -j | jq -r '.monitorID')"
current_monitor_name="$(hyprctl activeworkspace -j | jq -r '.monitor')"

# NOTE: add windowrule so those scratchpads
# have the tag scratchpad
# e.g.: windowrule = tag +scratchpad, class:kitty-scratch
function raise_or_run() {
  local class="$1"
  local runstr="$2"
  local has_uwsm="$3"
  local window
  window=$(hyprctl clients -j | jq "first(.[] | select(.class == \"$class\"))")

  if [[ "$window" ]]; then
    local window_ws window_address window_monitor is_focused is_visible
    window_ws=$(echo "$window" | jq -j ".workspace.name")
    window_address=$(echo "$window" | jq -j ".address")
    window_monitor=$(echo "$window" | jq -j ".monitor")
    is_focused=$(echo "$window" | jq '.focusHistoryID == 0')
    is_visible=$([[ "$window_monitor" == "$current_monitor" && "$window_ws" == "$current_ws" ]] && echo "true" || echo "false")
    if [[ "$is_visible" == "true" ]]; then
      if [[ "$is_focused" == "true" ]]; then
        local batch_args=""
        local is_window_grouped
        # hide
        is_window_grouped=$(echo "$window" | jq '.grouped | length > 0')
        if [ "$is_window_grouped" = "true" ]; then
          batch_args="dispatch moveoutofgroup active;"
        fi
        batch_args="$batch_args dispatch movetoworkspacesilent special:scratchpads,class:^($class)$;"
        hyprctl --batch "$batch_args" -q
      else
        # focus
        batch_args="dispatch focuswindow class:^($class)$;"
        batch_args="$batch_args dispatch alterzorder top,address:$window_address;"
        hyprctl --batch "$batch_args" -q
      fi
    else
      # focus
      local batch_args=""
      if [[ "$window_monitor" != "$current_monitor" ]]; then
        # HACK: move scratchpads ws to current monitor
        batch_args="dispatch moveworkspacetomonitor special:scratchpads $current_monitor_name;"
      fi
      batch_args="$batch_args dispatch movetoworkspace $current_ws,class:^($class)$;"
      batch_args="$batch_args dispatch focuswindow class:^($class)$;"
      batch_args="$batch_args dispatch alterzorder top,address:$window_address;"
      if [[ "$window_monitor" != "$current_monitor" ]]; then
        batch_args="$batch_args dispatch centerwindow;"
        # HACK: move cursor to window after it has been centered
        batch_args="$batch_args dispatch focuswindow class:^($class)$;"
      fi
      hyprctl --batch "$batch_args" -q
    fi
  else
    if [[ "$runstr" ]]; then
      if [[ "$has_uwsm" == "true" ]]; then
        # shellcheck disable=SC2086
        uwsm-app -- $runstr
      else
        hyprctl dispatch exec "$runstr" -q
      fi
    fi
  fi

  # hide all others scratchpads
  local windows_addresses
  windows_addresses=$(hyprctl clients -j | jq -r ".[] | select(.monitor == $current_monitor and .workspace.id == $current_ws and .class != \"$class\" and (.tags[]? | test(\"^scratchpad\"))) | .address")
  batch_args=""
  for window_address in $windows_addresses; do
    batch_args="$batch_args dispatch movetoworkspacesilent special:scratchpads,address:$window_address;"
  done
  hyprctl --batch "$batch_args" -q
}

function focus_last() {
  local window_class
  window_class=$(hyprctl clients -j | jq -r "[.[] | select((.tags[]? | test(\"^scratchpad\")))] | sort_by(.focusHistoryID) | .[0] | .class")
  raise_or_run "$window_class" ""
}

function process_scratchpad() {
  local window="$1"
  local ws_name="$2"

  if [ -n "$window" ]; then
    local window_ws window_monitor window_address is_focused is_visible
    window_ws=$(echo "$window" | jq -r ".workspace.name")
    window_monitor=$(echo "$window" | jq -r ".monitor")
    window_address=$(echo "$window" | jq -r ".address")
    is_focused=$(echo "$window" | jq '.focusHistoryID == 0')
    is_visible=$([[ "$window_monitor" == "$current_monitor" && "$window_ws" == "$current_ws" ]] && echo "true" || echo "false")

    if [[ "$is_visible" == "true" ]]; then
      if [[ "$is_focused" == "true" ]]; then
        if [[ "$ws_name" == tmpscratchpad* ]]; then
          # hide all
          local -a tmpscratchpads_windows
          local batch_args=""
          mapfile -t tmpscratchpads_windows < <(hyprctl clients -j | jq -c ".[] | select(.monitor == $current_monitor and .workspace.id == $current_ws and (.tags[]? | test(\"^tmpscratchpad\")))")
          for window in "${tmpscratchpads_windows[@]}"; do
            local window_address
            window_address=$(echo "$window" | jq -r ".address")
            batch_args="$batch_args dispatch movetoworkspacesilent special:$ws_name,address:$window_address;"
          done
          hyprctl --batch "$batch_args" -q
          exit 0
        else
          # hide
          hyprctl dispatch movetoworkspacesilent "special:$ws_name,address:$window_address" -q
          exit 0
        fi
      else
        if [[ "$ws_name" == tmpscratchpad* ]]; then
          # focus
          local batch_args="dispatch focuswindow address:$window_address;"
          batch_args="$batch_args dispatch alterzorder top,address:$window_address;"
          hyprctl --batch "$batch_args" -q
          exit 0
        fi
      fi
    fi
  fi
}

function toggle_scratchpad() {
  # if focused window is scratchpad, hide it
  # otherwise show all tmpscratchpads

  # process scratchpads created by --raise-or-run
  local -a scratchpads_windows
  mapfile -t scratchpads_windows < <(hyprctl clients -j | jq -c ".[] | select(.monitor == $current_monitor and .workspace.id == $current_ws and (.tags[]? | test(\"^scratchpad\")))")
  for window in "${scratchpads_windows[@]}"; do
    process_scratchpad "$window" "scratchpads"
  done

  # process scratchpads created by --toggle and --toggle-in
  local -a tmpscratchpads_windows
  mapfile -t tmpscratchpads_windows < <(hyprctl clients -j | jq -c "[.[] | select(.monitor == $current_monitor and .workspace.id == $current_ws and (.tags[]? | test(\"^tmpscratchpad\")))] | sort_by(.focusHistoryID) | .[]")
  for window in "${tmpscratchpads_windows[@]}"; do
    process_scratchpad "$window" "tmpscratchpads"
  done

  # show all tmpscratchpads and focus last tmpscratchpads
  local recent_tmpscratchpad_window_address window_address window_monitor_id
  local batch_args=""
  mapfile -t tmpscratchpads_windows < <(hyprctl clients -j | jq -c "[.[] | select((.monitor != $current_monitor or .workspace.id != $current_ws) and (.tags[]? | test(\"^tmpscratchpad\")))] | sort_by(.focusHistoryID) | .[]")
  recent_tmpscratchpad_window_address=$(echo "${tmpscratchpads_windows[0]}" | jq -r '.address')
  for window in "${tmpscratchpads_windows[@]}"; do
    window_address=$(echo "$window" | jq -r ".address")
    window_monitor_id=$(echo "$window" | jq -r ".monitor")
    batch_args="$batch_args dispatch movetoworkspace $current_ws,address:$window_address;"
    if [[ "$current_monitor" != "$window_monitor_id" ]]; then
      batch_args="$batch_args dispatch centerwindow;"
    fi
  done
  batch_args="$batch_args dispatch focuswindow address:$recent_tmpscratchpad_window_address;"
  batch_args="$batch_args dispatch alterzorder top,address:$recent_tmpscratchpad_window_address;"
  hyprctl --batch "$batch_args"

}

function toggle_in_scratchpad() {
  # move in or move out window from scratchpad

  local focused_window_in_tmpscratchpad
  focused_window_in_tmpscratchpad=$(hyprctl clients -j | jq -r ".[] | select(.focusHistoryID == 0 and (.tags[]? | test(\"^tmpscratchpad\")))")
  if [ -n "$focused_window_in_tmpscratchpad" ]; then
    # focused window is in scratchpad

    # move out from scratchpad
    local batch_args="dispatch tagwindow -tmpscratchpad;"
    batch_args="$batch_args dispatch movetoworkspacesilent $current_ws;"
    hyprctl --batch "$batch_args" -q
  else
    local is_focused_window_grouped
    is_focused_window_grouped=$(hyprctl activewindow -j | jq '.grouped | length > 0')
    # move in to scratchpad
    local batch_args="dispatch tagwindow +tmpscratchpad;"
    if [ "$is_focused_window_grouped" = "true" ]; then
      batch_args="$batch_args dispatch moveoutofgroup active;"
    fi
    batch_args="$batch_args dispatch movetoworkspacesilent special:tmpscratchpads;"
    hyprctl --batch "$batch_args" -q
  fi

}

while true; do
  case "$1" in
  -h | --help)
    cat <<EOF
Usage: $PROG [OPTIONS]

Options:
  -h, --help                  Show this help message.
  --raise-or-run CLASS CMD    Raise or run a window with given CLASS, launching CMD if not found.
  --focus-last                Focus the last used scratchpad window.
  --toggle                    Toggle visibility of scratchpad windows.
  --toggle-in                 Toggle the currently focused window in/out of the scratchpad.
EOF
    exit 0
    ;;
  --raise-or-run-uwsm)
    class="$2"
    cmd="$4"
    raise_or_run "$class" "$cmd" "true"
    shift 3
    ;;
  --raise-or-run)
    class="$2"
    cmd="$4"
    raise_or_run "$class" "$cmd" "false"
    shift 3
    ;;
  --focus-last)
    focus_last
    shift
    ;;
  --toggle)
    toggle_scratchpad
    shift
    ;;
  --toggle-in)
    toggle_in_scratchpad
    shift
    ;;
  --)
    # end of options; what's left in "$@" are the non-option args
    shift
    break
    ;;
  *)
    echo "Unknown option: $1"
    exit 1
    ;;
  esac
done
