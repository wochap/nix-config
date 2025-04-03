#!/usr/bin/env bash

# source theme colors
source "$HOME/.config/scripts/theme-colors.sh"

time=$(date +%Y-%m-%d_%I-%M-%S)
dir="$(xdg-user-dir PICTURES)/Screenshots"
filename="Screenshot_${time}"
EXPIRE_TIME=5000
grim_dest="$dir/grim_${filename}.png"
dest="$dir/${filename}.webp"

# notify
notify_user() {
  if [[ ! -e "$grim_dest" ]]; then
    exit 1
  fi

  optimize_image
  copy_to_cb "$dest"

  # generate thumbnail
  thumbnail_size="288x288"
  thumbnail=$(mktemp --suffix .png) || exit 1
  trap 'rm -f "$thumbnail"' exit
  magick "$grim_dest" -resize "$thumbnail_size>" -gravity center -background transparent -extent "$thumbnail_size" "$thumbnail"

  action=$(notify-send --app-name="Takeshot" --expire-time="$EXPIRE_TIME" --replace-id=699 --icon="$thumbnail" "Screen shooter" "Screenshot Saved" --action="open=Open" --action="edit=Edit" --action="png=Copy PNG")

  case $action in
  "edit")
    # NOTE: swappy doesn't support webp
    swappy -f "$grim_dest" -o "$dest" &
    ;;
  "open")
    rm -f "$grim_dest"
    xdg-open "$dest" &
    ;;
  "png")
    copy_to_cb "$grim_dest"
    ;;
  *)
    rm -f "$grim_dest"
    ;;
  esac
}

optimize_image() {
  magick "$grim_dest" -quality 85 "$dest"
}

copy_to_cb() {
  printf 'file://%s\n' "$1" | wl-copy -t text/uri-list
}

# countdown
countdown() {
  for sec in $(seq $1 -1 1); do
    notify-send --app-name="Takeshot" --expire-time=1000 --replace-id=698 --icon="accessories-screenshot" "Taking shot in $sec"
    sleep 1
  done
}

# take shots
shotnow() {
  grim "$grim_dest"
  notify_user
}

shot5() {
  countdown '5'
  sleep 1
  shotnow
}

kill_hyprpicker() {
  hyprpicker_pid=$(pgrep hyprpicker)
  if [ -n "$hyprpicker_pid" ]; then
    kill $hyprpicker_pid
  fi

}

kill_slurp() {
  slurp_pid=$(pgrep slurp)
  if [ -n "$slurp_pid" ]; then
    kill $slurp_pid
  fi
}

freeze_screen() {
  hyprpicker -r -z &
  hyprpicker_pid=$!
  wait $hyprpicker_pid

  # if hyprpicker is killed
  # kill slurp
  kill_slurp
}

shotarea() {
  if [[ -n $(pgrep slurp) ]]; then
    exit 0
  fi
  sh $0 --freeze &
  sleep 0.1
  area=$(slurp -d -b "${background}bf" -c "$primary" -F "Iosevka NF" -w 1)
  if [[ -z $area ]]; then
    kill_hyprpicker
    exit
  fi
  grim -g "$area" "$grim_dest"
  kill_hyprpicker
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
elif [[ "$1" == "--freeze" ]]; then
  freeze_screen
else
  echo -e "Available Options : --now --in5 --area"
fi

exit 0
