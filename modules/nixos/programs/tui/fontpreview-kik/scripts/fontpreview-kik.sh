#!/usr/bin/env bash
# Font preview with kitty icat kitten and fzf
# This is inspired by https://github.com/xlucn/fontpreview-ueberzug
# and https://github.com/sdushantha/fontpreview

# Checking for environment variables if available.
# These are compatible with original fontpreview.
SIZE=${FONTPREVIEW_SIZE:-800x800}
FONT_SIZE=${FONTPREVIEW_FONT_SIZE:-72}
BG_COLOR=${FONTPREVIEW_BG_COLOR:-#ffffff}
FG_COLOR=${FONTPREVIEW_FG_COLOR:-#000000}
TEXT_ALIGN=${FONTPREVIEW_TEXT_ALIGN:-center}
PREVIEW_TEXT=${FONTPREVIEW_PREVIEW_TEXT:-"ABCDEFGHIJKLM\nNOPQRSTUVWXYZ\n\
abcdefghijklm\nnopqrstuvwxyz\n1234567890\n!@#$\%^&*,.;:\n_-=+'\"|\\(){}[]"}

# kitty icat kitten related variables
IMAGE="/tmp/kfontpreview-img.png"
WIDTH=$FZF_PREVIEW_COLUMNS
HEIGHT=$FZF_PREVIEW_LINES
# fzf changes its preview paddings several times, its confusing
VPAD=$(fzf --version | {
  IFS='. ' read -r v1 v2 _
  [ "$v1" = 0 ] && [ "$v2" -le 26 ] && echo 0 || echo 4
})

usage() {
  echo "Usage: fontpreview-kik [-h] [-a ALIGNMENT] [-s FONT_SIZE] [-b BG] [-f FG] [-t TEXT]"
}

start() {
  touch "$IMAGE" || exit 1
}

stop() {
  rm -f "$IMAGE"
}

preview() {
  [ "$TEXT_ALIGN" = center ] || [ "$TEXT_ALIGN" = south ] || [ "$TEXT_ALIGN" = north ] || PADDING=50
  fontfile=$(echo "$1" | cut -f2)
  # In fzf the cols and lines are those of the preview pane
  magick -size "$SIZE" xc:"$BG_COLOR" -fill "$FG_COLOR" \
    -pointsize "$FONT_SIZE" -font "$fontfile" -gravity "$TEXT_ALIGN" \
    -annotate +"${PADDING:-0}+0" "$PREVIEW_TEXT" "$IMAGE" &&
    kitten icat --clear --transfer-mode=memory \
      --place="$((WIDTH - VPAD))x$((HEIGHT - 2))@2x1" --align center \
      --engine="magick" --stdin=no $IMAGE >/dev/tty
}

while getopts "a:hs:b:f:t:" arg; do
  case "$arg" in
  a) TEXT_ALIGN=$OPTARG ;;
  s) FONT_SIZE=$OPTARG ;;
  b) BG_COLOR=$OPTARG ;;
  f) FG_COLOR=$OPTARG ;;
  t) PREVIEW_TEXT=$OPTARG ;;
  *)
    usage
    exit
    ;;
  esac
done
shift $((OPTIND - 1))

if [ "$#" = 0 ]; then
  trap stop EXIT QUIT INT TERM
  # Prepare
  start
  # Export cli args as environment variables for preview command
  TEXT_ALIGN=$(echo "$TEXT_ALIGN" | sed 's/top/north/; s/bottom/south/; s/left/west/; s/right/east/')
  export FONTPREVIEW_TEXT_ALIGN="$TEXT_ALIGN"
  export FONTPREVIEW_FONT_SIZE="$FONT_SIZE"
  export FONTPREVIEW_BG_COLOR="$BG_COLOR"
  export FONTPREVIEW_FG_COLOR="$FG_COLOR"
  export FONTPREVIEW_PREVIEW_TEXT="$PREVIEW_TEXT"
  # The preview command runs this script again with an argument
  fc-list -f "%{family[0]}%{:style[0]=}\t%{file}\n" |
    grep -i '\.\(ttc\|otf\|ttf\)$' | sort | uniq |
    fzf --with-nth 1 --delimiter "\t" --layout=reverse --preview "sh $0 {}" \
      --preview-window "left:50%:noborder:wrap"
elif [ "$#" = 1 ]; then
  preview "$1"
fi
