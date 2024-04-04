#!/usr/bin/env bash

handle() {
  event=$(echo "$1" | cut -d ">" -f 1)
  if [[ "$event" == "submap" ]]; then
    submap=$(echo "$1" | cut -d ">" -f 3)
    printf -- '{"text":"%s"}\n' "$submap"
  fi
}

# `whie true` is required to make it work on ags
while true; do
  if read -r line < <(socat - "UNIX-CONNECT:/tmp/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"); then
    handle "$line"
  fi
done
