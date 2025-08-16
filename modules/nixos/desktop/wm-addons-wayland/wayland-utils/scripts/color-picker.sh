#!/usr/bin/env bash

notify() {
  TEMP_DIR=/tmp/xcolor
  EXPIRE_TIME=5000
  HEX_COLOR="$1"
  mkdir -p $TEMP_DIR
  HEX="${HEX_COLOR#\#}"
  FNAME="$TEMP_DIR/$HEX.png"
  magick -size 80x80 xc:"$HEX_COLOR" "$FNAME"
  COLOR_CODE="$HEX_COLOR"

  notify-send "Color picker" "$COLOR_CODE" --icon="$FNAME" --replace-id=697 --expire-time="$EXPIRE_TIME" --app-name="Hyprpicker"
}

if [[ -n $(pgrep hyprpicker) ]]; then
  exit 0
fi

color=$(hyprpicker -l -r -f hex -n)

if [ -z "$color" ]; then
  exit 0
fi

echo $color | wl-copy -n
notify $color
