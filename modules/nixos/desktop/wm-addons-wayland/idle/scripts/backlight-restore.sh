#!/usr/bin/env bash

dpms --on
brightnessctl --restore

# increase brightness if it is too low
DEVICES=$(find /sys/class/backlight -type l -printf "%f\n")
for device in $DEVICES; do
  val=$(brightnessctl --device "$device" get)
  max=$(brightnessctl --device "$device" max)
  percentage=$(echo "($val / $max) * 100" | bc -l)
  is_less_than_10=$(echo "$percentage < 10" | bc -l)
  if [ "$is_less_than_10" -eq 1 ]; then
    brightnessctl --device "$device" set "10%"
  fi
done
