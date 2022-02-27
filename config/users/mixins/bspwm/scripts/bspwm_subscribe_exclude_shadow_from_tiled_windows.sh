#!/usr/bin/env sh

bspc subscribe node_state | while read -r _ _ _ node state status; do
  if [[ "$state" == "tiled" ]]; then
    case "$status" in
      off) xprop -id "$node" -remove _BSPWM_NODE_TILED;;
      on) xprop -id "$node" -f _BSPWM_NODE_TILED 32c -set _BSPWM_NODE_TILED 1;;
    esac
  fi
done

