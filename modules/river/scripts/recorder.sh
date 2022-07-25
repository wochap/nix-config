#!/usr/bin/env bash

# source theme colors
. "/etc/scripts/theme-colors.sh"

stopfile=/tmp/_stop
time=$(date +%Y-%m-%d-%I-%M-%S)
dir="$(xdg-user-dir VIDEOS)/Recordings"
file="Recording_${time}.mp4"
EXPIRE_TIME=5000
dest="$dir/$file"

wait_recording() {
  pid=$!
  echo $pid >$stopfile
  wait $pid
  rm -f $stopfile
}

notify_user() {
  if [[ -e "$dest" ]]; then
    # generate thumbnail
    thumbnail_size=500
    thumbnail=$(mktemp --suffix .png) || exit 1
    trap 'rm -f "$thumbnail"' exit
    ffmpegthumbnailer -i "$dest" -o "$thumbnail" -s "$thumbnail_size"

    # TODO: copy to clipboard

    action=$(dunstify -t "$EXPIRE_TIME" --replace=699 -i "$thumbnail" "Video recording" "Recording Saved" --action "default,Open" --action "fm,Open in file manager")
  else
    dunstify -t "$EXPIRE_TIME" --replace=699 -i mpv "Video recording" "Recording Aborted."
  fi

  # TODO: Open in video editor?
  if [[ $action == "default" ]]; then
    xdg-open "$dest"
  fi
  if [[ $action == "fm" ]]; then
    xdg-open "$dir"
  fi
}

# countdown
countdown() {
  for sec in $(seq $1 -1 1); do
    dunstify -t 1000 --replace=699 "Recording in : $sec"
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

shotarea() {
  area=$(slurp -d -b "${background}bf" -c "$primary")
  if [[ -z $area ]]; then
    notify_user
    exit
  fi
  cd ${dir} && wf-recorder -g "$area" -f "$file" &
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
elif [[ "$1" == "--area" ]]; then
  shotarea
else
  echo -e "Available Options : --now --in5 --area"
fi

exit 0

