#!/usr/bin/env bash

# Monitors backlight changes using udevadm and jc.
# When a change event is detected, it reads the current brightness
# from sysfs and prints it as a percentage.

# Function to get the current backlight brightness information.
get_backlight_info() {
  # Find the first available backlight device.
  # This is usually sufficient as most systems have one.
  local backlight_device
  backlight_device=$(ls /sys/class/backlight/ | head -n 1)

  if [ -z "$backlight_device" ]; then
    return 1
  fi

  local base_path="/sys/class/backlight/$backlight_device"

  # Ensure the required files exist before trying to read them.
  if [ ! -f "$base_path/brightness" ] || [ ! -f "$base_path/max_brightness" ]; then
    return 1
  fi

  # Read the current and maximum brightness values.
  local current_brightness
  current_brightness=$(cat "$base_path/brightness")
  local max_brightness
  max_brightness=$(cat "$base_path/max_brightness")

  # Calculate the brightness percentage.
  # We check for max_brightness > 0 to avoid division by zero.
  if [ "$max_brightness" -gt 0 ]; then
    local percentage=$((current_brightness * 100 / max_brightness))
    printf -- "$percentage\n"
  else
    printf -- "$current_brightness\n"
  fi
}

case "$1" in
--listen)
  get_backlight_info

  # Start monitoring for udev events related to the backlight subsystem.
  udevadm monitor --subsystem-match=backlight --property |
    while IFS= read -r line; do
      # The udev event simply acts as a trigger.
      get_backlight_info
    done
  ;;
*)
  echo "Usage: $0 [--listen]" >&2
  exit 1
  ;;
esac
