#!/usr/bin/env bash

# Get list of active WireGuard interfaces
active_interfaces=$(wg show interfaces 2>/dev/null)

# Check if any interfaces are active
if [ -z "$active_interfaces" ]; then
  # No active interfaces
  echo '{"tooltip": "", "activeCount": 0}'
else
  # Convert space-separated list to newline-separated for tooltip
  tooltip=$(echo "$active_interfaces" | tr ' ' '\n')

  # Count the number of active interfaces
  count=$(echo "$active_interfaces" | wc -w)

  # Output JSON format
  echo "{\"tooltip\": \"$tooltip\", \"activeCount\": $count}"
fi
