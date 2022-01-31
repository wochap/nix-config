#!/usr/bin/env bash
# Toggles polybar and resizes bspwm padding.

LOCK_FILE="$HOME/.cache/bar.lck"

if [[ ! -f "$LOCK_FILE" ]]; then
    touch "$LOCK_FILE"
    polybar-msg cmd hide
    bspc config top_padding 0
else
    rm "$LOCK_FILE"
    bspc config top_padding $(($POLYBAR_HEIGHT + $POLYBAR_MARGIN))
    polybar-msg cmd show
fi
