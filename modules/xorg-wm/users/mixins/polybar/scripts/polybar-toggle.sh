#!/usr/bin/env bash

LOCK_FILE="$HOME/.cache/bar.lck"

if [[ ! -f "$LOCK_FILE" ]]; then
  touch "$LOCK_FILE"
  polybar-msg cmd hide
  bspc config top_padding 0
else
  rm "$LOCK_FILE"
  polybar-msg cmd show
fi
