#!/usr/bin/env bash

# A function to get the current bluetooth status and print it as JSON
print_status() {
  local powered="false"
  local scanning="false"
  local connected_devices=0

  # Check if bluetoothctl is available
  if ! command -v bluetoothctl &>/dev/null; then
    printf '{"powered": %s, "scanning": %s, "connected_devices": %d}\n' \
      "$powered" "$scanning" "$connected_devices"
    exit 1
  fi

  # Get controller information from bluetoothctl
  # We use a single call to bluetoothctl show for efficiency
  local controller_info
  controller_info=$(bluetoothctl show)

  # Check if the controller is powered on
  if echo "$controller_info" | grep -q "Powered: yes"; then
    powered="true"
  fi

  # Check if the controller is scanning for devices
  if echo "$controller_info" | grep -q "Discovering: yes"; then
    scanning="true"
  fi

  # Count the number of connected devices
  # 'bluetoothctl devices Connected' lists only connected devices.
  # We count the lines to get the number.
  connected_devices=$(bluetoothctl devices Connected | wc -l)

  # Print the status as a JSON object
  printf '{"powered": %s, "scanning": %s, "connected_devices": %d}\n' \
    "$powered" "$scanning" "$connected_devices"
}

# A function to set the bluetooth power state to 'on' or 'off'
set_power() {
  local state=$1
  # The 'power' command in bluetoothctl is idempotent, so no need to check state first.
  # It won't do anything if Bluetooth is already in the desired state.
  echo "power $state" | bluetoothctl >/dev/null
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
--status | '')
  # If '--status' is passed or no arguments are given,
  # just get the current status and exit.
  print_status
  ;;
--toggle)
  # Handle the second argument for on/off, or toggle if no argument
  case "$2" in
  on)
    set_power "on"
    ;;
  off)
    set_power "off"
    ;;
  '')
    # No argument given, so perform a classic toggle
    if bluetoothctl show | grep -q "Powered: yes"; then
      set_power "off"
    else
      set_power "on"
    fi
    ;;
  *)
    echo "Error: Invalid argument '$2' for --toggle. Use 'on', 'off', or no argument." >&2
    exit 1
    ;;
  esac
  ;;
*)
  echo "Usage: $0 [--listen | --status | --toggle [on|off]]" >&2
  exit 1
  ;;
esac
