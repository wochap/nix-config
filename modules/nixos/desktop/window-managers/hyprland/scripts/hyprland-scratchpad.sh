#!/usr/bin/env bash

PROG=$(basename $0)
TEMP=$(getopt --options h --longoptions help,raise-or-run:,focus-last,focus-last-workspace,focus-last-workspace-init,toggle,toggle-in -- "$@") || exit 1
eval set -- "$TEMP"

current_ws="$(hyprctl activeworkspace -j | jq -r '.id')"
current_monitor="$(hyprctl activeworkspace -j | jq -r '.monitorID')"

# NOTE: add windowrule so those scratchpads
# have the tag scratchpad
# e.g.: windowrule = tag +scratchpad, class:kitty-scratch
function raise_or_run() {
  class="$1"
  runstr="$2"

  window=$(hyprctl clients -j | jq ".[] | select(.class == \"$class\")")
  if [[ "$window" ]]; then
    window_ws=$(echo "$window" | jq -j ".workspace.name")
    window_monitor=$(echo "$window" | jq -j ".monitor")
    is_focused=$(echo "$window" | jq '.focusHistoryID == 0')
    is_visible=$([[ "$window_monitor" == "$current_monitor" && "$window_ws" == "$current_ws" ]] && echo "true" || echo "false")
    if [[ "$is_visible" == "true" ]]; then
      if [[ "$is_focused" == "true" ]]; then
        # hide
        hyprctl dispatch movetoworkspacesilent "special:scratchpads,class:^($class)$" -q
      else
        # focus
        batch_args="dispatch focuswindow class:^($class)$;"
        batch_args="$batch_args dispatch alterzorder top;"
        hyprctl --batch "$batch_args" -q
      fi
    else
      # focus
      batch_args="dispatch movetoworkspace $current_ws,class:^($class)$;"
      batch_args="$batch_args dispatch focuswindow class:^($class)$;"
      batch_args="$batch_args dispatch alterzorder top;"
      hyprctl --batch "$batch_args" -q
    fi
  else
    if [[ "$runstr" ]]; then
      hyprctl dispatch exec "$runstr" -q
    fi
  fi

  # hide all others scratchpads
  windows_addresses=$(hyprctl clients -j | jq -r ".[] | select(.monitor == $current_monitor and .workspace.id == $current_ws and .class != \"$class\" and (.tags[]? | test(\"^scratchpad\"))) | .address")
  batch_args=""
  for window_address in $windows_addresses; do
    batch_args="$batch_args dispatch movetoworkspacesilent special:scratchpads,address:$window_address;"
  done
  hyprctl --batch "$batch_args" -q
}

function focus_last() {
  window_class=$(hyprctl clients -j | jq -r "[.[] | select((.tags[]? | test(\"^scratchpad\")))] | sort_by(.focusHistoryID) | .[0] | .class")
  raise_or_run "$window_class" ""
}

function focus_last_ws() {
  monitor=$(hyprctl activeworkspace -j | jq -r .monitor)
  file="/tmp/hyprland-$monitor-last-ws"

  if [[ -f "$file" ]] && [[ $(wc -l <"$file") -eq 2 ]]; then
    prev_ws=$(sed -n '2p' "$file")
    hyprctl dispatch workspace "$prev_ws"
  else
    hyprctl dispatch workspace previous
  fi
}
function focus_last_ws_init() {
  function handle() {
    input="$1"
    event="${input%%>>*}"
    payload="${input#*>>}"

    # save last normal/special workspace
    if [[ "$event" == "workspacev2" ]]; then
      IFS=',' read -r ws_id ws_name <<<"$payload"
      monitor=$(hyprctl activeworkspace -j | jq -r .monitor)
      file="/tmp/hyprland-$monitor-last-ws"
      if [[ -n "$ws_id" ]]; then
        {
          echo "$ws_id"
          cat "$file" 2>/dev/null
        } | head -n 2 >"$file.tmp" && mv "$file.tmp" "$file"
      fi
    fi
  }

  socat -U - "UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" | while read -r line; do handle "$line"; done
}

function process_scratchpad() {
  window="$1"
  ws_name="$2"

  if [ -n "$window" ]; then
    window_ws=$(echo "$window" | jq -r ".workspace.name")
    window_monitor=$(echo "$window" | jq -r ".monitor")
    window_address=$(echo "$window" | jq -r ".address")
    is_focused=$(echo "$window" | jq '.focusHistoryID == 0')
    is_visible=$([[ "$window_monitor" == "$current_monitor" && "$window_ws" == "$current_ws" ]] && echo "true" || echo "false")

    if [[ "$is_visible" == "true" ]]; then
      if [[ "$is_focused" == "true" ]]; then
        if [[ "$ws_name" == tmpscratchpad* ]]; then
          # hide all
          mapfile -t tmpscratchpads_windows < <(hyprctl clients -j | jq -c ".[] | select(.monitor == $current_monitor and .workspace.id == $current_ws and (.tags[]? | test(\"^tmpscratchpad\")))")
          batch_args=""
          for window in "${tmpscratchpads_windows[@]}"; do
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
          batch_args="dispatch focuswindow address:$window_address;"
          batch_args="$batch_args dispatch alterzorder top;"
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

  # process scratchpads created by hyprland-focus-toggle.sh
  mapfile -t scratchpads_windows < <(hyprctl clients -j | jq -c ".[] | select(.monitor == $current_monitor and .workspace.id == $current_ws and (.tags[]? | test(\"^scratchpad\")))")
  for window in "${scratchpads_windows[@]}"; do
    process_scratchpad "$window" "scratchpads"
  done

  # process scratchpads created by hyprland-scratch-toggle.sh
  mapfile -t tmpscratchpads_windows < <(hyprctl clients -j | jq -c "[.[] | select(.monitor == $current_monitor and .workspace.id == $current_ws and (.tags[]? | test(\"^tmpscratchpad\")))] | sort_by(.focusHistoryID) | .[]")
  for window in "${tmpscratchpads_windows[@]}"; do
    process_scratchpad "$window" "tmpscratchpads"
  done

  # show all tmpscratchpads and focus last tmpscratchpads
  mapfile -t tmpscratchpads_windows < <(hyprctl clients -j | jq -c "[.[] | select((.monitor != $current_monitor or .workspace.id != $current_ws) and (.tags[]? | test(\"^tmpscratchpad\")))] | sort_by(.focusHistoryID) | .[]")
  recent_tmpscratchpad_window_address=$(echo "${tmpscratchpads_windows[0]}" | jq -r '.address')
  batch_args=""
  for window in "${tmpscratchpads_windows[@]}"; do
    window_address=$(echo "$window" | jq -r ".address")
    batch_args="$batch_args dispatch movetoworkspace $current_ws,address:$window_address;"
  done
  batch_args="$batch_args dispatch focuswindow address:$recent_tmpscratchpad_window_address;"
  batch_args="$batch_args dispatch alterzorder top;"
  hyprctl --batch "$batch_args"

}

function toggle_in_scratchpad() {
  # move in or move out window from scratchpad

  focused_window_in_tmpscratchpad=$(hyprctl clients -j | jq -r ".[] | select(.focusHistoryID == 0 and (.tags[]? | test(\"^tmpscratchpad\")))")
  if [ -n "$focused_window_in_tmpscratchpad" ]; then
    # focused window is in scratchpad

    # move out from scratchpad
    batch_args="dispatch tagwindow -tmpscratchpad;"
    batch_args="$batch_args dispatch movetoworkspacesilent $current_ws;"
    hyprctl --batch "$batch_args" -q
  else
    is_focused_window_grouped=$(hyprctl activewindow -j | jq '.grouped | length > 0')
    # move in to scratchpad
    batch_args="dispatch tagwindow +tmpscratchpad;"
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
  -h, --help                      Show this help message.
  --raise-or-run CLASS CMD        Raise or run a window with given CLASS, launching CMD if not found.
  --focus-last                    Focus the last used scratchpad window.
  --focus-last-workspace          Switch to the last used workspace on the current monitor.
  --focus-last-workspace-init     Initialize workspace tracking via Hyprland events.
  --toggle                        Toggle visibility of scratchpad windows.
  --toggle-in                     Toggle the currently focused window in/out of the scratchpad.
EOF
    exit 0
    ;;
  --raise-or-run)
    class="$2"
    cmd="$4"
    raise_or_run "$class" "$cmd"
    shift 3
    ;;
  --focus-last)
    focus_last
    shift
    ;;
  --focus-last-workspace)
    focus_last_ws
    shift
    ;;
  --focus-last-workspace-init)
    focus_last_ws_init
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
