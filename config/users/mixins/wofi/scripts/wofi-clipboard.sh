#!/usr/bin/env bash

# HACK: window padding mess up wofi location
wofi_width="400"
wofi_padding="100"
wofi_real_width=$(echo "$wofi_width+$wofi_padding*2" | bc)
monitor_size=$(swaymsg -t get_outputs | jq '.[] | select(.focused) | .rect.width,.rect.height')
monitor_width=$(printf "$monitor_size" | sed -n '1p')
monitor_height=$(printf "$monitor_size" | sed -n '2p')
xoffset=$(echo "$monitor_width/2-$wofi_real_width/2" | bc)
yoffset=$(echo "$monitor_height*0.2" | bc)

clipman pick --tool="wofi" --tool-args="--width $wofi_width --lines 15 --location top_left --yoffset $yoffset --xoffset $xoffset"
