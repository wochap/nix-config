#!/usr/bin/env bash

# A function to get the current bluetooth status and print it as JSON
get_status() {
  POWERED="false"
  SCANNING="false"
  CONNECTED_DEVICES=0

  # Check if bluetoothctl is available
  if ! command -v bluetoothctl &>/dev/null; then
    printf '{"powered": %s, "scanning": %s, "connected_devices": %d}\n' \
      "$POWERED" "$SCANNING" "$CONNECTED_DEVICES"
    exit 1
  fi

  # Get controller information from bluetoothctl
  # We use a single call to bluetoothctl show for efficiency
  local controller_info
  controller_info=$(bluetoothctl show)

  # Check if the controller is powered on
  if echo "$controller_info" | grep -q "Powered: yes"; then
    POWERED="true"
  fi

  # Check if the controller is scanning for devices
  if echo "$controller_info" | grep -q "Discovering: yes"; then
    SCANNING="true"
  fi

  # Count the number of connected devices
  # 'bluetoothctl devices Connected' lists only connected devices.
  # We count the lines to get the number.
  CONNECTED_DEVICES=$(bluetoothctl devices Connected | wc -l)

  # Print the status as a JSON object
  printf '{"powered": %s, "scanning": %s, "connected_devices": %d}\n' \
    "$POWERED" "$SCANNING" "$CONNECTED_DEVICES"
}

case "$1" in
--listen)
  # Monitor the D-Bus system bus for signals from the BlueZ service.
  # Any change in connection, power state, or scanning status will
  # emit a signal from 'org.bluez'.
  dbus-monitor --system "sender='org.bluez'" | while read -r line; do
    # When a signal is detected, print 'true' to indicate a change.
    # This allows other scripts or widgets to know when to refresh the status.
    printf -- 'true\n'
  done
  ;;
--get-status | '')
  # If '--get-status' is passed or no arguments are given,
  # just get the current status and exit.
  get_status
  ;;
*)
  echo "Usage: $0 [--listen | --get-status]" >&2
  exit 1
  ;;
esac
