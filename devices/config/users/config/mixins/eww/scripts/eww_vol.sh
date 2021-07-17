#!/usr/bin/env bash

getIsMuted() {
  isMuted=$(pulsemixer --get-mute)
  echo $isMuted
}

getCurrentVolume() {
  echo "$(pulsemixer --get-volume | awk '{print $1}')"
}

writeIcon() {
  isMuted="$1"
  if [[ "$isMuted" == "0" ]]; then
    echo "" > /tmp/vol-icon
  else
    echo "" > /tmp/vol-icon
  fi
}

# Create pipes for eww_vol widget values
# Update icon and volume value
if [ -p /tmp/vol ]; then
  true
else
  coproc (mkfifo /tmp/vol > /dev/null 2>&1)
  currentVolume=$(getCurrentVolume)
  echo "$currentVolume" > /tmp/vol &
fi
if [ -p /tmp/vol-icon ]; then
  true
else
  coproc (mkfifo /tmp/vol-icon > /dev/null 2>&1)
  isMuted=$(getIsMuted)
  writeIcon $isMuted &
fi

# Cancel timeout to close eww_vol
script_name="eww_vol_close.sh"
for pid in $(pgrep -f $script_name); do
  kill -9 $pid
done

incrementValue=5

# Show eww_vol widget
eww_wid="$(xdotool search --name 'Eww - vol' || true)"
if [ ! -n "$eww_wid" ]; then
  coproc (eww open vol > /dev/null 2>&1)
fi

case $1 in
  up)
    # Update volume value
    pulsemixer --max-volume 100 --change-volume +"$incrementValue"
    paplay /etc/blop.wav &
    currentVolume=$(getCurrentVolume)
    echo "$currentVolume" > /tmp/vol
  ;;
  down)
    # Update volume value
    pulsemixer --change-volume -"$incrementValue"
    paplay /etc/blop.wav &
    currentVolume=$(getCurrentVolume)
    echo $currentVolume > /tmp/vol
  ;;
  mute)
    # Update icon
    pulsemixer --toggle-mute
    isMuted=$(getIsMuted)
    writeIcon $isMuted
  ;;
esac

# Start timeout to close eww_vol
/etc/eww_vol_close.sh &
