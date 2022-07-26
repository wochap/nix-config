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

  notify-send "Color picker" "$COLOR_CODE" --icon="$FNAME" --expire-time="$EXPIRE_TIME"
}

# Get color position
position=$(slurp -b 00000000 -p)

if [ -z "$position" ]; then
  exit
fi

# Sleep at least for a second to prevet issues with grim always
# returning improper color.
sleep 1

# Store the hex color value using graphicsmagick
color=$(
  grim -g "$position" -t png - |
    gm convert - -format '%[pixel:p{0,0}]' txt:- |
    tail -n 1 |
    rev |
    cut -d ' ' -f 1 |
    rev
)

echo $color | wl-copy -n
notify $color

