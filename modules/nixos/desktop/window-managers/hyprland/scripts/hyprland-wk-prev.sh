#!/usr/bin/env bash

function init() {
  function handle {
    input="$1"
    event="${input%%>>*}"

    # save last normal/special workspace
    if [[ "$event" == "workspacev2" ]]; then
      monitor=$(hyprctl activeworkspace -j | jq -r .monitor)
      wk="${input#*>>}"
      wk="${wk%%,*}"
      file="/tmp/hyprland-$monitor-last-wk"
      if [[ -n "$wk" ]]; then
        {
          echo "$wk"
          cat "$file" 2>/dev/null
        } | head -n 2 >"$file.tmp" && mv "$file.tmp" "$file"
      fi
    elif [[ "$event" == "activespecialv2" ]]; then
      monitor=$(hyprctl activeworkspace -j | jq -r .monitor)
      wk="${input#*>>}"
      wk="${wk%%,*}"
      file="/tmp/hyprland-$monitor-last-wk-special"
      if [[ -n "$wk" ]]; then
        {
          echo "$wk"
          cat "$file" 2>/dev/null
        } | head -n 2 >"$file.tmp" && mv "$file.tmp" "$file"
      fi
    fi
  }

  socat - "UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" | while read -r line; do handle "$line"; done
}

function dispatch() {
  is_special="$1"

  if [[ -n "$is_special" ]]; then
    echo "TODO"
  else
    monitor=$(hyprctl activeworkspace -j | jq -r .monitor)
    file="/tmp/hyprland-$monitor-last-wk"

    if [[ -f "$file" ]] && [[ $(wc -l <"$file") -eq 2 ]]; then
      prev_wk=$(sed -n '2p' "$file")
      hyprctl dispatch workspace "$prev_wk"
    else
      hyprctl dispatch workspace previous
    fi
  fi
}

case "$1" in
--init)
  init
  ;;
--dispatch)
  dispatch "$2"
  ;;
*)
  echo "Usage: $0 [--init | --dispatch <is_special>]"
  exit 1
  ;;
esac
