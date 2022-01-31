bspc subscribe node_state | while read -r _ _ _ node state status; do
  if [[ "$state" == "floating" ]]; then
    case "$status" in
      off) xprop -id "$node" -remove _PICOM_SHADOW;;
      on) xprop -id "$node" -f _PICOM_SHADOW 32c -set _PICOM_SHADOW 1;;
    esac
  fi
done

# bspc subscribe node_focus | while read -r _ _ _ focused_node; do
#   floating_nodes=$(bspc query --nodes --node .floating)
#   nodes=$(bspc query --nodes)
#   for node in $nodes
#   do
#     is_node_floating=$([[ " ${floating_nodes[@]} " =~ " ${node} " ]] && echo "true" || echo "false")
#     if [[ $is_node_floating == "true" || $node == $focused_node  ]]
#     then
#       xprop -id "$node" -f _PICOM_SHADOW 32c -set _PICOM_SHADOW 1
#     else
#       xprop -id "$node" -remove _PICOM_SHADOW
#     fi
#   done
# done
