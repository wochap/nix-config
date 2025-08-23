#!/usr/bin/env bash

# A function to get the current network status and print it as JSON
get_status() {
  TYPE="Disconnected"
  SSID=""
  SIGNAL=0
  CONNECTED="false"

  # Check for an active wired connection first
  WIRED_DEVICE=$(ip -j link | jq -r '.[] | select(.ifname | test("^e(n|th)")) | select(.operstate == "UP") | .ifname' | head -n 1)
  if [ -n "$WIRED_DEVICE" ]; then
    TYPE="wired"
    SSID="Wired"
    SIGNAL=100
    CONNECTED="true"
  else
    # If no wired connection, check for an active Wi-Fi connection using nmcli.
    # We look for the line starting with '*' which indicates the active connection.
    WIFI_INFO=$(nmcli -t -f IN-USE,SSID,SIGNAL dev wifi list --rescan no | grep '^\*')
    TYPE="wifi"
    if [ -n "$WIFI_INFO" ]; then
      CONNECTED="true"
      # The terse output from nmcli is colon-separated.
      # SSID is the 2nd field, and SIGNAL is the 3rd.
      SSID=$(echo "$WIFI_INFO" | cut -d ':' -f 2)
      SIGNAL=$(echo "$WIFI_INFO" | cut -d ':' -f 3)
    fi
  fi

  printf '{"type": "%s", "ssid": "%s", "signal": %d, "connected": %s}\n' \
    "$TYPE" "$SSID" "$SIGNAL" "$CONNECTED"
}

case "$1" in
--listen)
  # This correctly watches for any signal sent by the NetworkManager service
  # TODO: use busctl
  dbus-monitor --system "sender='org.freedesktop.NetworkManager'" | while read -r line; do
    printf -- 'true\n'
  done
  ;;
--get-status | '')
  get_status
  ;;
*)
  echo "Usage: $0 [--listen | --get-status]" >&2
  exit 1
  ;;
esac
