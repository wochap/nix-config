#!/usr/bin/env bash

# A function to get the current network status and print it as JSON
print_status() {
  local wired_device
  local wifi_device
  local result="{}"

  wired_device=$(ip -j link | jq -r '.[] | select(.ifname | test("^e(n|th)"))')
  wifi_device=$(ip -j link | jq -r '.[] | select(.ifname | test("^wl"))')

  # Check for an active wired connection first
  if [ -n "$wired_device" ]; then
    local connected
    connected=$([ "$(echo "$wired_device" | jq -r '.operstate')" = "UP" ] && echo true || echo false)
    result=$(echo "$result" | jq \
      --argjson connected "$connected" \
      '.wired = {type: "wired", powered: true, connected: $connected}')
  fi

  if [ -n "$wifi_device" ]; then
    local wifi_info
    local connected="false"
    local powered
    local ssid=""
    local signal=0

    powered=$(iwctl device list | grep -q '\s\+on\s\+' && echo true || echo false)

    # Get Wi-Fi details using nmcli
    # We look for the line starting with '*' which indicates the active connection.
    wifi_info=$(nmcli -t -f IN-USE,SSID,SIGNAL dev wifi list --rescan no | grep '^\*')
    if [ -n "$wifi_info" ]; then
      connected="true"
      # The terse output from nmcli is colon-separated.
      # SSID is the 2nd field, and SIGNAL is the 3rd.
      ssid=$(echo "$wifi_info" | cut -d ':' -f 2)
      signal=$(echo "$wifi_info" | cut -d ':' -f 3)
    fi

    result=$(echo "$result" | jq \
      --argjson connected "$connected" \
      --argjson powered "$powered" \
      --arg ssid "$ssid" \
      --argjson signal "$signal" \
      '.wifi = {type: "wifi", powered: $powered, connected: $connected, ssid: $ssid, signal: $signal}')
  fi

  # Print the status as a JSON object
  printf '%s' "$result"
}

# A function to set the wifi power state to 'on' or 'off'
set_wifi_power() {
  local state=$1
  if [[ "$state" == "on" ]]; then
    # Unblocks the wireless device
    rfkill unblock wlan
    # Then power on the software controller
    # iwctl device wlan0 set-property Powered "$state"
  elif [[ "$state" == "off" ]]; then
    # Power off the software controller first
    # iwctl device wlan0 set-property Powered "$state"
    # Blocks the wireless device
    rfkill block wlan
  fi
}

case "$1" in
--listen)
  # This correctly watches for any signal sent by the NetworkManager service
  # TODO: use busctl
  dbus-monitor --system "sender='org.freedesktop.NetworkManager'" | while read -r line; do
    printf -- 'true\n'
  done
  ;;
--status | '')
  print_status
  ;;
--toggle-wifi)
  # Handle the second argument for on/off, or toggle if no argument
  case "$2" in
  on)
    set_wifi_power "on"
    ;;
  off)
    set_wifi_power "off"
    ;;
  '')
    # No argument given, so perform a classic toggle
    if iwctl device list | grep -q '\s\+on\s\+'; then
      set_wifi_power "off"
    else
      set_wifi_power "on"
    fi
    ;;
  *)
    echo "Error: Invalid argument '$2' for --toggle-wifi. Use 'on', 'off', or no argument." >&2
    exit 1
    ;;
  esac
  ;;
*)
  echo "Usage: $0 [--listen | --status | --toggle-wifi [on|off]]" >&2
  exit 1
  ;;
esac
