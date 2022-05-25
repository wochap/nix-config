#!/usr/bin/env bash

# HACK: window padding mess up wofi location
wofi_width="300"
wofi_padding="100"
wofi_real_width=$(echo "$wofi_width+$wofi_padding*2" | bc)
monitor_size=$(swaymsg -t get_outputs | jq '.[] | select(.focused) | .rect.width,.rect.height')
monitor_width=$(printf "$monitor_size" | sed -n '1p')
monitor_height=$(printf "$monitor_size" | sed -n '2p')
xoffset=$(echo "$monitor_width/2-$wofi_real_width/2" | bc)
yoffset=$(echo "$monitor_height*0.2" | bc)

## Get info
IFACE="$(nmcli | grep -i interface | awk '/interface/ {print $2}')"
STATUS="$(nmcli radio wifi)"
INTERFACE="$(nmcli device | awk '$2=="wifi" {print $1}')"

if (ping -c 1 archlinux.org) &>/dev/null; then
  if [[ $STATUS == *"enable"* ]]; then
    if [[ $IFACE == e* ]]; then
      amogus="Connected"
      connected="Disconnect from WiFi"
    else
      amogus="Connected"
      connected="Disconnect from WiFi"
    fi
    SSID="$(iwgetid -r)"
  fi
else
  SSID="Disconnected"
  PIP="NA"
  amogus="Offline"
  connected="Connect to WiFi"
fi

## Icons
launch_cli="Open Network Manager"
launch="Open Connection Editor"

options="$connected\n$launch_cli\n$launch"

## Main
chosen="$(echo -e "$options" | wofi --dmenu --width "$wofi_width" --lines 5 --location top_left --yoffset "$yoffset" --xoffset "$xoffset")"

case $chosen in
$connected)
  if [[ $STATUS == *"enable"* ]]; then
    nmcli radio wifi off
  else
    nmcli radio wifi on
  fi
  ;;
$launch_cli)
  $HOME/.config/kitty/scripts/kitty-nmtui.sh
  ;;
$launch)
  nm-connection-editor
  ;;
esac

