#!/usr/bin/env bash

PROG=$(basename $0)
TEMP=$(getopt --options h --longoptions help,init -- "$@") || exit 1
eval set -- "$TEMP"

function get_last_ws_file_name() {
  local hyprland_signature="$HYPRLAND_INSTANCE_SIGNATURE"
  local monitor_name="$1"

  echo "/tmp/hyprland-$monitor_name-last-ws-$hyprland_signature"
}

function focus_last_ws() {
  monitor=$(hyprctl activeworkspace -j | jq -r .monitor)
  file=$(get_last_ws_file_name "$monitor")

  if [[ -f "$file" ]] && [[ $(wc -l <"$file") -eq 2 ]]; then
    prev_ws=$(sed -n '2p' "$file")
    hyprctl dispatch focusworkspaceoncurrentmonitor "$prev_ws"
  else
    hyprctl dispatch focusworkspaceoncurrentmonitor previous
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
      file=$(get_last_ws_file_name "$monitor")
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
    focus_last_ws_init
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
  focus_last_ws
fi
