#!/usr/bin/env bash

print_status() {
  if legion_cli --donotexpecthwmon rapid-charging-status 2>/dev/null | grep -q "True"; then
    echo "true"
  else
    echo "false"
  fi
}

toggle() {
  # Handle the second argument for on/off, or toggle if no argument
  case "$1" in
  on)
    local is_active
    is_active=$(print_status)
    if [[ "$is_active" == "false" ]]; then
      pkexec legion_cli --donotexpecthwmon rapid-charging-enable
    fi
    print_status
    ;;
  off)
    local is_active
    is_active=$(print_status)
    if [[ "$is_active" == "true" ]]; then
      pkexec legion_cli --donotexpecthwmon rapid-charging-disable
    fi
    print_status
    ;;
  '')
    local is_active
    is_active=$(print_status)
    if [[ "$is_active" == "true" ]]; then
      pkexec legion_cli --donotexpecthwmon rapid-charging-disable
    else
      pkexec legion_cli --donotexpecthwmon rapid-charging-enable
    fi
    print_status
    ;;
  *)
    echo "Error: Invalid argument '$1' for --toggle. Use 'on', 'off', or no argument." >&2
    exit 1
    ;;
  esac
}

case "$1" in
--status)
  print_status
  ;;
--toggle)
  toggle "$2"
  ;;
*)
  echo "Usage: $0 [--toggle | --status [on|off]]" >&2
  exit 1
  ;;
esac
