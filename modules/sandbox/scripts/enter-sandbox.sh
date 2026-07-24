#!/usr/bin/env bash
set -euo pipefail

CONTAINER="${1:-sandbox}"

if ! nixos-container status "$CONTAINER" | grep -q "up"; then
  echo "Container '$CONTAINER' is down, starting it..."
  nixos-container start "$CONTAINER"
fi

exec machinectl shell "gean@$CONTAINER" /run/current-system/sw/bin/zsh
