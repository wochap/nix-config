#!/usr/bin/env bash

DEVICES=$(find /sys/class/backlight -type l -printf "%f\n")

# NOTE: will break on whitespace
for device in $DEVICES; do
  brightnessctl -d "$device" set "$1"
done

