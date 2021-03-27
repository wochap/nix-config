#!/usr/bin/env bash

set -euo pipefail

mute () {
  muted=$(pulsemixer --get-mute)
  if [[ "$muted" == "0" ]]; then
    echo "" > /tmp/vol-icon
  else
    echo "" > /tmp/vol-icon
  fi
}
if [ -p /tmp/vol ]; then
  true
else
  mkfifo /tmp/vol && echo "$(pulsemixer --get-volume | awk '{print $1}')" > /tmp/vol &
fi
if [ -p /tmp/vol-icon ]; then
  true
else
  mkfifo /tmp/vol-icon && mute &
fi

script_name="eww_vol_close.sh"
for pid in $(pgrep -f $script_name); do
  kill -9 $pid
done

# start=$SECONDS
value=5

eww_wid="$(xdotool search --name 'Eww - vol' || true)"
if [ ! -n "$eww_wid" ]; then
  eww open vol
fi

case $1 in
  up)
    currentVolume=$(pulsemixer --get-volume | awk '{print $1}')
    if [[ "$currentVolume" -ge "100" ]]; then
      pulsemixer --max-volume 100
    else
      pulsemixer --change-volume +"$value"
    fi
    echo $(pulsemixer --get-volume | awk '{print $1}') > /tmp/vol
    mute
    paplay /etc/blop.wav
  ;;
  down)
    pulsemixer --change-volume -"$value"
    echo $(pulsemixer --get-volume | awk '{print $1}') > /tmp/vol
    mute
    paplay /etc/blop.wav
  ;;
  mute)
    muted=$(pulsemixer --get-mute)
    if [[ "$muted" == "0" ]]; then
      pulsemixer --toggle-mute
      echo "" > /tmp/vol-icon
    else
      pulsemixer --toggle-mute
      echo "" > /tmp/vol-icon
    fi
  ;;
esac

/etc/eww_vol_close.sh
