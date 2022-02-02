#!/usr/bin/env bash

stopfile=/tmp/_stop
time=$(date +%Y-%m-%d-%I-%M-%S)
dir="$(xdg-user-dir VIDEOS)/Recordings"
file="Recording_${time}.mp4"
EXPIRE_TIME=5000

wait_recording() {
  pid=$!
  echo $pid >$stopfile
  wait $pid
  rm -f $stopfile
}

notify_user() {
  if [[ -e "$dir/$file" ]]; then
    dunstify -t "$EXPIRE_TIME" --replace=699 -i mpv "Video recording" "Recording Saved"
  else
    dunstify -t "$EXPIRE_TIME" --replace=699 -i mpv "Video recording" "Recording Deleted."
  fi
}

# countdown
countdown() {
  for sec in $(seq $1 -1 1); do
    dunstify -t 1000 --replace=699 -i $dir/$file "Recording in : $sec"
    sleep 1
  done
}

# take shots
shotnow() {
  cd ${dir} && wf-recorder -f "$file" &
  wait_recording
  notify_user
}

shot5() {
  countdown '5'
  sleep 1
  shotnow
}

shot10() {
  countdown '10'
  sleep 1
  shotnow
}

shotwin() {
  cd ${dir} && wf-recorder -g "$(swaymsg -t get_tree | jq -r '.. | select(.pid? and .visible?) | .rect | "\(.x),\(.y) \(.width)x\(.height)"' | slurp)" -f "$file" &
  wait_recording
  notify_user
}

shotarea() {
  cd ${dir} && wf-recorder -g "$(slurp)" -f "$file" &
  wait_recording
  notify_user
}

if [[ ! -d "$dir" ]]; then
  mkdir -p "$dir"
fi

# If a recording session is already active, stop that one.
if [[ -f "$stopfile" ]]; then
  pid=$(cat $stopfile)
  if [[ $(ps aux | grep "$pid" | wc -l) -eq 2 ]]; then
    # TODO: use $pid
    killall -s 2 wf-recorder
    exit 0
  else
    rm -f $stopfile
  fi
fi


if [[ "$1" == "--now" ]]; then
  shotnow
elif [[ "$1" == "--in5" ]]; then
  shot5
elif [[ "$1" == "--in10" ]]; then
  shot10
elif [[ "$1" == "--win" ]]; then
  shotwin
elif [[ "$1" == "--area" ]]; then
  shotarea
else
  echo -e "Available Options : --now --in5 --in10 --win --area"
fi

exit 0

