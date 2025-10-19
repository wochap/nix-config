#!/usr/bin/env bash

# Keyboard USB device IDs
KBD_ID_VENDOR="048d"
KBD_ID_PRODUCT="c104"

# Helper function to find the keyboard's power control file path
_get_keyboard_power_path() {
  for dir in /sys/bus/usb/devices/*; do
    if [[ -f "$dir/idVendor" && -f "$dir/idProduct" ]]; then
      if [[ "$(cat "$dir/idVendor")" == "$KBD_ID_VENDOR" && "$(cat "$dir/idProduct")" == "$KBD_ID_PRODUCT" ]]; then
        echo "$dir/power/control"
        return 0
      fi
    fi
  done
  return 1 # Not found
}

print_status() {
  local kbd_path
  kbd_path=$(_get_keyboard_power_path)
  if [[ -z "$kbd_path" ]]; then
    echo "Error: Keyboard device $KBD_ID_VENDOR:$KBD_ID_PRODUCT not found." >&2
    return 1
  fi
  if [[ "$(cat "$kbd_path")" == "auto" ]]; then
    echo "on"
  else
    echo "off"
  fi
}

toggle() {
  local kbd_path
  kbd_path=$(_get_keyboard_power_path)
  if [[ -z "$kbd_path" ]]; then
    echo "Error: Keyboard device $KBD_ID_VENDOR:$KBD_ID_PRODUCT not found." >&2
    exit 1
  fi

  local current_status
  current_status=$(cat "$kbd_path")

  case "$2" in
  on) # Enable autosuspend (power saving)
    if [[ "$current_status" != "auto" ]]; then
      pkexec bash -c "echo auto > $kbd_path"
    fi
    ;;
  off) # Disable autosuspend (high power)
    if [[ "$current_status" != "on" ]]; then
      pkexec bash -c "echo on > $kbd_path"
    fi
    ;;
  '') # Toggle between on and auto
    if [[ "$current_status" == "auto" ]]; then
      # It's currently in power-saving ('auto'), so switch to high-power ('on')
      pkexec bash -c "echo on > $kbd_path"
    else
      # It's currently in high-power ('on'), so switch to power-saving ('auto')
      pkexec bash -c "echo auto > $kbd_path"
    fi
    ;;
  *)
    echo "Error: Invalid argument '$2' for --toggle. Use 'on', 'off', or no argument." >&2
    exit 1
    ;;
  esac
  echo -n "Autosuspend is now: "
  print_status
}

case "$1" in
--status)
  print_status
  ;;
--toggle)
  toggle "$@"
  ;;
*)
  echo "Usage: $0 [--status | --toggle [on|off]]" >&2
  exit 1
  ;;
esac
