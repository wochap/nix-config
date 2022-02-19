#!/usr/bin/env bash

stopfile=/tmp/_stop
time=$(date +%Y-%m-%d-%I-%M-%S)
dir="$(xdg-user-dir VIDEOS)/Recordings"
file="Recording_${time}.mp4"
EXPIRE_TIME=5000
fps=30
delay=0
dest="$dir/$file"

wait_recording() {
  pid=$!
  echo $pid >$stopfile
  wait $pid
  rm -f $stopfile
}

notify_user() {
  if [[ -e "$dest" ]]; then
    copy_to_cb
    action=$(dunstify -t "$EXPIRE_TIME" --replace=699 -i mpv "Video recording" "Recording Saved" --action "default,Open" --action "fm,Open in file manager")
  else
    dunstify -t "$EXPIRE_TIME" --replace=699 -i mpv "Video recording" "Recording Aborted"
  fi

  # TODO: Open in video editor?
  if [[ $action == "default" ]]; then
    xdg-open "$dest"
  fi
  if [[ $action == "fm" ]]; then
    xdg-open "$dir"
  fi
}

copy_to_cb() {
  echo ""
  # TODO: xclip can't copy videos
  # xclip -selection clipboard -t video/mp4 "$dest"
}

select-region() {
  if [[ $geom ]]; then
    echo "${geom//[x+]/ }"
  else
    slop -nof "%w %h %x %y"
  fi
}

record_region() {
  X="$1"
  Y="$2"
  W="$3"
  H="$4"
  local ffmpeg_opts="-y -f x11grab -show_region 1 -ss $delay -s ${W}x${H} -i :0.0+${X},${Y} -framerate ${fps}"
  ffmpeg $ffmpeg_opts "$dest" &
}

# countdown
countdown() {
  for sec in $(seq $1 -1 1); do
    dunstify -t 1000 --replace=699 "Recording in : $sec"
    sleep 1
  done
}

shot5() {
  read -r W H X Y < <(select-region)
  [[ -z "$W$H$X$Y" ]] && exit 1

  countdown '5'
  sleep 1

  # TODO: kill picom?

  record_region "$X" "$Y" "$W" "$H"
  wait_recording

  # TODO: transform to gif?

  notify_user
}

shotarea() {
  read -r W H X Y < <(select-region)
  [[ -z "$W$H$X$Y" ]] && exit 1

  # TODO: kill picom?

  record_region "$X" "$Y" "$W" "$H"
  wait_recording

  # TODO: transform to gif?

  notify_user
}

if [[ ! -d "$dir" ]]; then
  mkdir -p "$dir"
fi

# If a recording session is already active, stop that one.
if [[ -f "$stopfile" ]]; then
  pid=$(cat $stopfile)

  if [[ $(ps aux | grep "$pid" | wc -l) -eq 2 ]]; then
    kill $pid
    exit 0
  else
    rm -f $stopfile
  fi
fi

if [[ "$1" == "--in5" ]]; then
  shot5
elif [[ "$1" == "--area" ]]; then
  shotarea
else
  echo -e "Available Options : --in5 --area"
fi

exit 0
