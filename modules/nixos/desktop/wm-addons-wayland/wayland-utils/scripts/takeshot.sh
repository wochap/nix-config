#!/usr/bin/env bash

# source theme colors
source "$HOME/.config/scripts/theme-colors.sh"

time=$(date +%Y-%m-%d_%I-%M-%S)
dir="$(xdg-user-dir PICTURES)/Screenshots"
file="Screenshot_${time}.png"
EXPIRE_TIME=5000
dest="$dir/$file"

# notify
notify_user() {
  if [[ ! -e "$dest" ]]; then
    exit 1
  fi

  copy_to_cb

  # generate thumbnail
  thumbnail_size="288x288"
  thumbnail=$(mktemp --suffix .png) || exit 1
  trap 'rm -f "$thumbnail"' exit
  magick "$dest" -resize "$thumbnail_size>" -gravity center -background transparent -extent "$thumbnail_size" "$thumbnail"

  action=$(notify-send --app-name="Takeshot" --expire-time="$EXPIRE_TIME" --replace-id=699 --icon="$thumbnail" "Screen shooter" "Screenshot Saved" --action="open=Open" --action="edit=Edit")

  case $action in
  "edit")
    swappy -f "$dest" -o "$dest" &
    ;;
  "open")
    xdg-open "$dest" &
    ;;
  esac
}

copy_to_cb() {
  wl-copy -t image/png <"$dest"
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
  grim "$dest"
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
  grim -g "$area" "$dest"
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
