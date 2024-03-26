#!/usr/bin/env bash

# source theme colors
. "/etc/scripts/theme-colors.sh"

stopfile=/tmp/_stop
time=$(date +%Y-%m-%d_%I-%M-%S)
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
  if [[ ! -e "$dest" ]]; then
    exit 1
  fi

  # TODO: copy to clipboard

  # generate thumbnail
  thumbnail_size=500
  last_thumbnail_size="288x288"
  thumbnail=$(mktemp --suffix .png) || exit 1
  trap 'rm -f "$thumbnail"' exit
  ffmpegthumbnailer -i "$dest" -o "$thumbnail" -s "$thumbnail_size"
  magick "$thumbnail" -resize "$last_thumbnail_size>" -gravity center -background transparent -extent "$last_thumbnail_size" "$thumbnail"

  action=$(notify-send --app-name="Recorder" --expire-time="$EXPIRE_TIME" --replace-id=691 --icon="$thumbnail" "Video recording" "Recording saved" --action="open=Open" --action="open_in_fm=Open in file manager")

  # TODO: Open in video editor?
  case $action in
  "open_in_fm")
    xdg-open "$dir" &
    ;;
  "open")
    xdg-open "$dest" &
    ;;
  esac
}

# countdown
countdown() {
  for sec in $(seq $1 -1 1); do
    notify-send --app-name="Recorder" --expire-time=1000 --replace-id=692 --icon="screenrecorder" "Recording in $sec"
    sleep 1
  done
}

# take shots
shotnow() {
  cd "$dir" && wl-screenrec -f "$file" &
  wait_recording
  notify_user
}

shot5() {
  countdown '5'
  sleep 1
  shotnow
}

shotarea() {
  area=$(slurp -d -b "${background}bf" -c "$primary" -F "Iosevka NF" -w 1)
  if [[ -z $area ]]; then
    exit
  fi
  cd "$dir" && wl-screenrec -g "$area" -f "$file" &
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
    killall -s 2 wl-screenrec
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
