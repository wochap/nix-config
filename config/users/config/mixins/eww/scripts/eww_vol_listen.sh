#!/usr/bin/env bash

writeIcon() {
  isMuted="$1"
  if [[ "$isMuted" == "0" ]]; then
    echo "" > /tmp/vol-icon
  else
    echo "" > /tmp/vol-icon
  fi
}

# Grab pactl args
# pactl subscribe | grep --line-buffered "sink" | xargs -d "\n" -n1 /etc/scripts/eww_vol_listen.sh
type=$(echo "$1" | awk '{print $4}')
event=$(echo "$1" | awk '{print $2}' | tr -d "'")
if [[ "$type" == "sink" ]] && [[ "$event" == "change" ]]; then
  true
else
  exit
fi

isMuted=$(pulsemixer --get-mute)
currentVolume="$(pulsemixer --get-volume | awk '{print $1}')"
prevIsMuted=$(cat /tmp/vol-isMuted)
prevCurrentVolume=$(cat /tmp/vol-currentVolume)

# Exit if state didn't change
if [[ "$prevIsMuted" == "$isMuted" ]] && [[ "$prevCurrentVolume" == "$currentVolume" ]]; then
  exit
else
  true
fi

# Create pipes for eww_vol widget values
# Update icon and volume value
if [ -p /tmp/vol ]; then
  true
else
  if [ -f /tmp/vol ]; then
    rm /tmp/vol
  fi
  mkfifo /tmp/vol > /dev/null 2>&1
  echo "$currentVolume" > /tmp/vol
fi
if [ -p /tmp/vol-icon ]; then
  true
else
  if [ -f /tmp/vol-icon ]; then
    rm /tmp/vol-icon
  fi
  mkfifo /tmp/vol-icon > /dev/null 2>&1
  writeIcon $isMuted
fi

# Cancel timeout to close eww_vol
script_name="eww_vol_close.sh"
for pid in $(pgrep -f $script_name); do
  kill -9 $pid
done

# Show eww_vol widget
eww_wid="$(xdotool search --name 'Eww - vol' || true)"
if [ ! -n "$eww_wid" ]; then
  eww open vol > /dev/null 2>&1
fi

# Write eww variables
writeIcon $isMuted &
echo "$currentVolume" > /tmp/vol &
echo "$isMuted" > /tmp/vol-isMuted &
echo "$currentVolume" > /tmp/vol-currentVolume &

# Play sound
# TODO: add delay between
# paplay triggers `change sink` event
paplay /etc/assets/blop.wav &

# Start timeout to close eww_vol
/etc/scripts/eww_vol_close.sh &
