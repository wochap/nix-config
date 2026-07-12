#!/usr/bin/env bash

IFACE="wg0"

print_status() {
  # Try to grab the IPv4 address of wg0. Errors are hidden if wg0 doesn't exist.
  IP=$(ip -4 addr show dev "$IFACE" 2>/dev/null | awk '/inet / {print $2}' | cut -d/ -f1)

  if [[ -n "$IP" ]]; then
    # If an IP exists, it's UP. Print JSON with true, the IP, and Waybar fields.
    printf '{ "status": true, "ip": "%s" }\n' "$IP" "$IP"
  else
    # If no IP exists, it's DOWN.
    printf '{ "status": false, "ip": "" }\n'
  fi
}

listen_status() {
  print_status

  # 'ip monitor address' streams events whenever any IP address is added or removed on the system
  ip monitor address | while read -r line; do
    # Only react if the event line mentions our WireGuard interface
    if [[ "$line" == *"$IFACE"* ]]; then
      print_status
    fi
  done
}

if [[ "$1" == "--status" ]]; then
  print_status
elif [[ "$1" == "--listen" ]]; then
  listen_status
else
  echo -e "Available Options : --status --listen"
fi
