#!/usr/bin/env bash

# Threshold in MHz. If the highest boosting core is below this, we are stuck.
THRESHOLD_MHZ=800

get_status() {
  # Extract the highest MHz value currently running across all 16 threads
  local max_mhz=$(grep "cpu MHz" /proc/cpuinfo | awk '{print $4}' | cut -d. -f1 | sort -nr | head -n1)

  if [[ -z "$max_mhz" ]]; then
    echo "false"
    return
  fi

  if [[ "$max_mhz" -lt "$THRESHOLD_MHZ" ]]; then
    echo "true"
  else
    echo "false"
  fi
}

cmd_listen() {
  # 1. Print the initial state immediately when the script starts
  local current_state=$(get_status)
  echo "$current_state"

  # 2. Listen to systemd DBus for sleep/wake events
  # PrepareForSleep emits "boolean true" when suspending, and "boolean false" when resuming.
  dbus-monitor --system "type='signal',interface='org.freedesktop.login1.Manager',member='PrepareForSleep'" 2>/dev/null |
    while read -r line; do

      # We only care when the system is waking up ("boolean false")
      if echo "$line" | grep -q "boolean false"; then

        # Give the system exactly 5 seconds to stabilize power states
        sleep 5

        local new_state=$(get_status)

        # Only print if the state actually changed
        if [[ "$new_state" != "$current_state" ]]; then
          echo "$new_state"
          current_state="$new_state"
        fi
      fi
    done
}

case "$1" in
--status)
  get_status
  ;;
--listen)
  cmd_listen
  ;;
*)
  echo "Usage: $0 {--status|--listen}"
  exit 1
  ;;
esac
