#!/usr/bin/env bash

# source theme colors
source "$HOME/.config/scripts/theme-colors.sh"

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
  sh $0 --freeze &
  sleep 0.1
  area=$(slurp -d -b "${background}bf" -c "$primary" -F "Iosevka NF" -w 1)
  if [[ -z $area ]]; then
    kill_wayfreeze
    exit
  fi
  grim_dest=$(mktemp /tmp/ocr-math-XXXXXX.png)
  grim -g "$area" "$grim_dest"
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
