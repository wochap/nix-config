#!/usr/bin/env bash

EXPIRE_TIME=5000

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

if [[ "$1" == "--freeze" ]]; then
  freeze_screen
  exit
fi

sh $0 --freeze &
sleep 0.1

if [[ -n $(pgrep slurp) ]]; then
  # slurp is already running
  exit 0
fi

area=$(slurp -d -b "${background}bf" -c "$primary" -F "Iosevka NF" -w 1 -f "%w:%h")

kill_wayfreeze

if [[ -z $area ]]; then
  # slurp canceled
  exit
fi

# copy to clipboard
printf "%s" "$area" | wl-copy --trim-newline --type text/plain

# show notification
notify-send --app-name="Ruler" --app-icon="accessories-screenshot" --icon="accessories-screenshot" --hint=int:transient:1 "width:height" "$area"
