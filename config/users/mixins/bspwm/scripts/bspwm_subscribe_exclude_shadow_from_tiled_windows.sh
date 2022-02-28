#!/usr/bin/env sh

bspc subscribe node_state node_add | while read -r type _ _ node state status; do
  if [[ $type == "node_state" ]]; then
    if [[ "$state" == "tiled" ]]; then
      case "$status" in
      off) xprop -id "$node" -remove _BSPWM_NODE_TILED ;;
      on) xprop -id "$node" -f _BSPWM_NODE_TILED 32c -set _BSPWM_NODE_TILED 1 ;;
      esac
    fi
  else
    node="$state"
    tiled_nodes=($(bspc query --nodes --node .window.local.tiled))
    if [[ " ${tiled_nodes[*]} " =~ " ${node} " ]]; then
      xprop -id "$node" -f _BSPWM_NODE_TILED 32c -set _BSPWM_NODE_TILED 1
    fi
  fi
done
