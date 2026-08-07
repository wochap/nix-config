#!/usr/bin/env bash
set -euo pipefail

CONTAINER="sandbox"
RESTART=0

while [[ $# -gt 0 ]]; do
  case $1 in
    --restart)
      RESTART=1
      shift
      ;;
    -*)
      echo "Unknown option: $1"
      exit 1
      ;;
    *)
      CONTAINER="$1"
      shift
      ;;
  esac
done

if ! nixos-container status "$CONTAINER" | grep -q "up"; then
  echo "Container '$CONTAINER' is down, starting it..."
  nixos-container start "$CONTAINER"
elif [[ $RESTART -eq 1 ]]; then
  echo "Container '$CONTAINER' is up, restarting it..."
  nixos-container restart "$CONTAINER"
fi

exec machinectl shell "gean@$CONTAINER" /run/current-system/sw/bin/zsh
