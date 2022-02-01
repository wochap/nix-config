#!/usr/bin/env bash

# HACK: window padding mess up wofi location
wofi_width="900"
wofi_padding="100"
wofi_real_width=$(echo "$wofi_width+$wofi_padding*2" | bc)
monitor_size=$(swaymsg -t get_outputs | jq '.[] | select(.focused) | .rect.width,.rect.height')
monitor_width=$(printf "$monitor_size" | sed -n '1p')
monitor_height=$(printf "$monitor_size" | sed -n '2p')
xoffset=$(echo "$monitor_width/2-$wofi_real_width/2" | bc)
yoffset="300"

wofi --show drun,run --width "$wofi_width" --lines 7 --columns 3 --location top_left --yoffset "$yoffset" --xoffset "$xoffset"
