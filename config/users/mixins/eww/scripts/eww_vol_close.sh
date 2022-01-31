#!/usr/bin/env bash

set -euo pipefail

eww_wid="$(xdotool search --name 'Eww - vol' || true)"
start=$SECONDS

while [ -n "$eww_wid" ]; do
  duration=$(( SECONDS - start ))
  if [[ $duration -gt 1 ]]; then
    eww close vol
    eww_wid="$(xdotool search --name 'Eww - vol' || true)"
  fi
  sleep 0.2
done
