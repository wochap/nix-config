#!/usr/bin/env bash

# source theme colors
source "$HOME/.config/scripts/theme-colors.sh"

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

main() {
  if [[ -n $(pgrep slurp) ]]; then
    exit 0
  fi
  # wayfreeze stores a screencopy as its backing surface. Capture that surface
  # without the shader, then restore the shader while the area is selected.
  disable_screen_shader
  sh $0 --freeze &
  sleep 0.1
  restore_screen_shader
  area=$(slurp -d -b "${background}bf" -c "$primary" -F "Iosevka NF" -w 1)
  if [[ -z $area ]]; then
    kill_wayfreeze
    exit
  fi
  grim_dest=$(mktemp /tmp/ocr-math-XXXXXX.png)
  capture_grim -g "$area" "$grim_dest"
  kill_wayfreeze
  pix2tex "$grim_dest" | awk -F': ' '{print $2}' | wl-copy --trim-newline
  # TODO: https://github.com/qwinsi/tex2typst
  rm "$grim_dest"
  result=$(wl-paste)
  if [[ -n "$result" ]]; then
    notify-send --app-name="ocr math" --hint=int:transient:1 "OCR Math Completed" "Math Text Extracted and Copied"
  fi
}

if [[ "$1" == "--freeze" ]]; then
  freeze_screen
else
  main
fi

exit 0
