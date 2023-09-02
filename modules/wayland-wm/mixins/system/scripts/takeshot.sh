#!/usr/bin/env bash

# source theme colors
. "/etc/scripts/theme-colors.sh"

time=$(date +%Y-%m-%d-%I-%M-%S)
dir="$(xdg-user-dir PICTURES)/Screenshots"
file="Screenshot_${time}.jpg"
EXPIRE_TIME=5000
dest="$dir/$file"

# notify
notify_user() {
  if [[ -e "$dest" ]]; then
    copy_to_cb

    # generate thumbnail
    thumbnail_size="288x288"
    thumbnail=$(mktemp --suffix .png) || exit 1
    trap 'rm -f "$thumbnail"' exit
    magick "$dest" -resize "$thumbnail_size>" -gravity center -background transparent -extent "$thumbnail_size" "$thumbnail"

    action=$(dunstify --appname="Takeshot" -t "$EXPIRE_TIME" --replace=699 -i "$thumbnail" "Screen shooter" "Screenshot Saved" --action "default,Edit" --action "open,Open")
  else
    exit 1
    # dunstify -t "$EXPIRE_TIME" --replace=699 "Screen shooter" "Screenshot Aborted."
  fi

  if [[ $action == "default" ]]; then
    swappy -f "$dest" -o "$dest" &
  elif [[ $action == "open" ]]; then
    xdg-open "$dest" &
  fi
}

copy_to_cb() {
  wl-copy -t image/png < "$dest"
}

# countdown
countdown() {
  for sec in $(seq $1 -1 1); do
    dunstify -t 1000 --replace=698 -i "accessories-screenshot" "Taking shot in : $sec"
    sleep 1
  done
}

# take shots
shotnow() {
  cd ${dir} && grim - | swappy -f - -o "$file" -
  notify_user
}

shot5() {
  countdown '5'
  sleep 1
  shotnow
}

shotarea() {
  area=$(slurp -d -b "${background}bf" -c "$primary")
  if [[ -z $area ]]; then
    notify_user
    exit
  fi
  grim -g "$area" "$dest"
  notify_user
}

if [[ ! -d "$dir" ]]; then
  mkdir -p "$dir"
fi

if [[ "$1" == "--now" ]]; then
  shotnow
elif [[ "$1" == "--in5" ]]; then
  shot5
elif [[ "$1" == "--area" ]]; then
  shotarea
else
  echo -e "Available Options : --now --in5 --area"
fi

exit 0

