#!/usr/bin/env bash

BACKGROUNDS_PATH="${HOME}/Pictures/backgrounds"

preview() {
  WIDTH=$FZF_PREVIEW_COLUMNS
  HEIGHT=$FZF_PREVIEW_LINES
  # fzf changes its preview paddings several times, its confusing
  VPAD=$(fzf --version | {
    IFS='. ' read -r v1 v2 _
    [ "$v1" = 0 ] && [ "$v2" -le 26 ] && echo 0 || echo 4
  })
  IMAGE="$1"
  IMAGE_NAME=$(basename "$IMAGE" | sed 's/\.[^.]*$//')
  THUMBNAILS_FOLDER="${BACKGROUNDS_PATH}/.thumbnails"
  IMAGE_RESIZED="${THUMBNAILS_FOLDER}/${IMAGE_NAME}.jpg"
  if [ ! -d "$THUMBNAILS_FOLDER" ]; then
    mkdir "$THUMBNAILS_FOLDER"
  fi
  if [[ ! -e "$IMAGE_RESIZED" ]]; then
    convert "$IMAGE" -resize 1000x1000 "$IMAGE_RESIZED"
  fi
  kitten icat --clear --transfer-mode=memory \
    --place="$((WIDTH - VPAD))x$((HEIGHT - 2))@2x1" --align center \
    --stdin=no "$IMAGE_RESIZED" >/dev/tty
}

if [[ "$1" == "--preview" ]]; then
  preview "$2"
  exit 0
fi

items=$(find "${BACKGROUNDS_PATH}/" -maxdepth 1 -type f)
selected=$(
  printf "%s\n" "${items[@]}" | fzf --layout=reverse --preview "sh $0 --preview {}" \
    --preview-window "left:50%:noborder"
)
if [[ -n "$selected" ]]; then
  swww img "$selected"
fi
