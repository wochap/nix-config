#!/usr/bin/env bash

# source theme colors
source "$HOME/.config/scripts/theme-colors.sh"

time=$(date +%Y-%m-%d_%I-%M-%S)
dir="$(xdg-user-dir PICTURES)/Screenshots"
filename="Screenshot_${time}"
EXPIRE_TIME=5000
grim_dest="$dir/grim_${filename}.png"
dest="$dir/${filename}.webp"
screen_shader=""
screen_shader_disabled=false

disable_screen_shader() {
  if $screen_shader_disabled; then
    return
  fi

  screen_shader=$(hyprctl getoption decoration.screen_shader | sed -n '1s/^str:[[:space:]]*//p')
  if hyprctl keyword decoration:screen_shader "" >/dev/null; then
    screen_shader_disabled=true
    # Let Hyprland render an unfiltered frame before a screencopy client runs.
    sleep 0.05
  fi
}

restore_screen_shader() {
  if ! $screen_shader_disabled; then
    return
  fi

  if hyprctl keyword decoration:screen_shader "$screen_shader" >/dev/null; then
    screen_shader_disabled=false
    sleep 0.05
  fi
}

capture_grim() {
  local status

  disable_screen_shader
  grim "$@"
  status=$?
  restore_screen_shader
  return "$status"
}

trap restore_screen_shader EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

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

  action=$(notify-send --app-name="Takeshot" --app-icon="$thumbnail" --icon="$thumbnail" --hint="string:image-path:$thumbnail" "Screen shooter" "Screenshot Saved" --action="open=Open" --action="edit=Edit" --action="png=Copy PNG")

  case $action in
  "edit")
    # NOTE: satty doesn't support webp
    satty -f "$grim_dest" -o "$dest" &
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
  shotclip -- "$1"
}

# countdown
countdown() {
  for sec in $(seq $1 -1 1); do
    notify-send --app-name="Takeshot" --expire-time=1000 --app-icon="accessories-screenshot" --icon="accessories-screenshot" --hint=int:transient:1 "Taking shot in $sec"
    sleep 1
  done
}

# take shots
shotnow() {
  capture_grim "$grim_dest"
  notify_user
}

shot5() {
  countdown '5'
  sleep 1
  shotnow
}

kill_wayfreeze() {
  wayfreeze_pid=$(pgrep wayfreeze)
  if [ -n "$wayfreeze_pid" ]; then
    kill $wayfreeze_pid
  fi

}

kill_slurp() {
  slurp_pid=$(pgrep slurp)
  if [ -n "$slurp_pid" ]; then
    kill $slurp_pid
  fi
}

freeze_screen() {
  wayfreeze --hide-cursor &
  wayfreeze_pid=$!
  wait $wayfreeze_pid

  # if wayfreeze is killed
  # kill slurp
  kill_slurp
}

shotarea() {
  if [[ -n $(pgrep slurp) ]]; then
    exit 0
  fi

  # wayfreeze stores a screencopy as its backing surface. Capture that surface
  # without the shader, then restore the shader while the area is selected.
  disable_screen_shader
  sh "$0" --freeze &
  sleep 0.1
  restore_screen_shader
  area=$(slurp -d -b "${background}bf" -c "$primary" -F "Iosevka NF" -w 1)
  if [[ -z $area ]]; then
    kill_wayfreeze
    exit
  fi
  capture_grim -g "$area" "$grim_dest"
  kill_wayfreeze
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
