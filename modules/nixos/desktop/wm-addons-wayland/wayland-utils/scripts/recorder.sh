#!/usr/bin/env bash

# source theme colors
source "$HOME/.config/scripts/theme-colors.sh"

stopfile=/tmp/_stop
time=$(date +%Y-%m-%d_%I-%M-%S)
dir="$(xdg-user-dir VIDEOS)/Recordings"
file="Recording_${time}.mp4"
EXPIRE_TIME=5000
dest="$dir/$file"
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

trap restore_screen_shader EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

print_status() {
  if [[ -f "$stopfile" ]]; then
    printf -- 'true\n'
  else
    printf -- 'false\n'
  fi
}

listen_status() {
  # Print the initial state
  print_status

  # Wait for events and call print_status every time the file changes
  inotifywait -m -e create -e delete /tmp/ 2>/dev/null | while read -r target_dir action event_file; do
    if [[ "$event_file" == "_stop" ]]; then
      print_status
    fi
  done
}

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

  copy_to_cb

  # generate thumbnail
  thumbnail_size=500
  last_thumbnail_size="288x288"
  thumbnail=$(mktemp --suffix .png) || exit 1
  trap 'rm -f "$thumbnail"' exit
  ffmpegthumbnailer -i "$dest" -o "$thumbnail" -s "$thumbnail_size"
  magick "$thumbnail" -resize "$last_thumbnail_size>" -gravity center -background transparent -extent "$last_thumbnail_size" "$thumbnail"

  action=$(notify-send --app-name="Recorder" --app-icon="$thumbnail" --icon="$thumbnail" --hint="string:image-path:$thumbnail" "Video recording" "Recording saved" --action="open=Open" --action="open_in_fm=Open in file manager")

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

copy_to_cb() {
  shotclip -- "$dest"
}

# countdown
countdown() {
  for sec in $(seq $1 -1 1); do
    notify-send --app-name="Recorder" --expire-time=1000 --app-icon="screenrecorder" --icon="screenrecorder" --hint=int:transient:1 "Recording in $sec"
    sleep 1
  done
}

# take shots
shotnow() {
  disable_screen_shader
  cd "$dir" && wl-screenrec -f "$file" &
  wait_recording
  restore_screen_shader
  notify_user
}

shot5() {
  countdown '5'
  sleep 1
  shotnow
}

shotarea() {
  if [[ -n $(pgrep slurp) ]]; then
    exit 0
  fi
  area=$(slurp -d -b "${background}bf" -c "$primary" -F "Iosevka NF" -w 1)
  if [[ -z $area ]]; then
    exit
  fi
  disable_screen_shader
  cd "$dir" && wl-screenrec -g "$area" -f "$file" &
  wait_recording
  restore_screen_shader
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
    rm -f $stopfile
    exit 0
  else
    rm -f $stopfile
  fi
fi

if [[ "$1" == "--status" ]]; then
  print_status
elif [[ "$1" == "--listen" ]]; then
  listen_status
elif [[ "$1" == "--now" ]]; then
  shotnow
elif [[ "$1" == "--in5" ]]; then
  shot5
elif [[ "$1" == "--area" ]]; then
  shotarea
else
  echo -e "Available Options : --now --in5 --area --status --listen"
fi

exit 0
