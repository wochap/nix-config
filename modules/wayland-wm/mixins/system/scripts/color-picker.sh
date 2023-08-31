#!/usr/bin/env bash

notify() {
  TEMP_DIR=/tmp/xcolor
  EXPIRE_TIME=5000
  HEX_COLOR="$1"
  mkdir -p $TEMP_DIR
  HEX="${HEX_COLOR#\#}"
  FNAME="$TEMP_DIR/$HEX.png"
  convert -size 80x80 xc:"$HEX_COLOR" "$FNAME"
  COLOR_CODE="$HEX_COLOR"

  notify-send "Color picker" "$COLOR_CODE" --icon="$FNAME" --expire-time="$EXPIRE_TIME" --app-name="Hyprpicker"
}

color=$(hyprpicker -f hex -n)

if [ -z "$color" ]; then
  exit 1
fi

echo $color | wl-copy -n
notify $color

