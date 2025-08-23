#!/usr/bin/env bash

namespace="$1"

function handle() {
  hyprctl clients -j | jq "[.[] | select(.workspace.name == \"special:$namespace\")] | length"
}

handle
socat -U - "UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" | while read -r line; do handle "$line"; done
