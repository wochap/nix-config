#!/usr/bin/env bash

PROG=$(basename $0)
TEMP=$(getopt --options h --longoptions help,init -- "$@") || exit 1
eval set -- "$TEMP"

# Returns state filepath
function get_filepath() {
  local hyprland_signature="$HYPRLAND_INSTANCE_SIGNATURE"
  local monitor_name monitor_id
  monitor_id=$(hyprctl activeworkspace -j | jq -r .monitorID)
  monitor_name=$(hyprctl activeworkspace -j | jq -r .monitor)

  echo "/tmp/hyprland-last-ws-$monitor_id-$monitor_name-$hyprland_signature"
}

function init() {
  function handle() {
    local input="$1"
    local event="${input%%>>*}"
    local payload="${input#*>>}"

    # save last normal/special workspace
    if [[ "$event" == "workspacev2" ]]; then
      local ws_id ws_name
      IFS=',' read -r ws_id ws_name <<<"$payload"
      local filepath
      filepath=$(get_filepath)

      if [[ -n "$ws_id" ]]; then
        {
          echo "$ws_id"
          cat "$filepath" 2>/dev/null
        } | head -n 2 >"$filepath.tmp" && mv "$filepath.tmp" "$filepath"
      fi
    fi
  }

  socat -U - "UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" | while read -r line; do handle "$line"; done
}

function focus_previous_ws() {
  local filepath
  filepath=$(get_filepath)

  if [[ -f "$filepath" ]] && [[ $(wc -l <"$filepath") -eq 2 ]]; then
    prev_ws=$(sed -n '2p' "$filepath")
    hyprctl dispatch focusworkspaceoncurrentmonitor "$prev_ws"
  else
    hyprctl dispatch focusworkspaceoncurrentmonitor previous
  fi
}

while true; do
  case "$1" in
  -h | --help)
    cat <<EOF
Usage: $PROG [OPTIONS]

Options:
  -h, --help                      Show this help message.
  --init                          Initialize workspace tracking via Hyprland events.

If you run the script with no options, it automatically switches to the last
used workspace on the current monitor.
EOF
    exit 0
    ;;
  --init)
    init
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

if [[ $# -eq 0 ]]; then
  focus_previous_ws
fi
