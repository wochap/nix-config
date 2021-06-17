bspc subscribe node_state | while read -r _ _ _ node state status; do
    if [[ "$state" == "floating" ]]; then
        case "$status" in
            off) xprop -id "$node" -remove _PICOM_SHADOW;;
            on) xprop -id "$node" -f _PICOM_SHADOW 32c -set _PICOM_SHADOW 1;;
        esac
    fi
done
