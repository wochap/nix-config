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

  if [ "$state" = "on" ]; then
    # Unblock the hardware kill switch first
    rfkill unblock bluetooth
    # Then power on the software controller
    # echo "power on" | bluetoothctl >/dev/null
  elif [ "$state" = "off" ]; then
    # Power off the software controller first
    # echo "power off" | bluetoothctl >/dev/null
    # Then block the hardware kill switch
    rfkill block bluetooth
  fi
}

case "$1" in
--listen)
  # Only refresh for property changes. Listening to every line emitted by
  # BlueZ creates a feedback loop: `bluetoothctl devices Connected` briefly
  # registers an advertisement monitor, which emits more BlueZ signals and
  # causes this script to query the status again.
  dbus-monitor --system \
    "type='signal',sender='org.bluez',interface='org.freedesktop.DBus.Properties',member='PropertiesChanged',path_namespace='/org/bluez'" \
    | while read -r line; do
      # dbus-monitor prints a multi-line payload for each signal. Emit exactly
      # once per signal instead of once per output line.
      if [[ $line == signal\ * ]]; then
        printf -- 'true\n'
      fi
    done
  ;;
--status | '')
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
