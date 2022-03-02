#!/usr/bin/env bash
## Script to take screenshots with maim

time=$(date +%Y-%m-%d-%I-%M-%S)
dir="$(xdg-user-dir PICTURES)/Screenshots"
file="Screenshot_${time}.jpg"
EXPIRE_TIME=5000

# notify
notify_user() {
  if [[ -e "$dir/$file" ]]; then
    copy_to_cb
    action=$(dunstify -t "$EXPIRE_TIME" --replace=699 -i "$dir/$file" "Screen shooter" "Screenshot Saved" --action "default,Edit")
  else
    exit 1
    # dunstify -t "$EXPIRE_TIME" --replace=699 -i "org.xfce.screenshooter" "Screen shooter" "Screenshot Aborted."
  fi

  if [[ $action == "default" ]]; then
    pinta "${dir}/$file" &
  fi
}

copy_to_cb() {
  xclip -selection clipboard -t image/png "$dir/$file"
}

# countdown
countdown() {
  for sec in $(seq $1 -1 1); do
    dunstify -t 1000 --replace=699 -i $dir/$file "Taking shot in : $sec"
    sleep 1
  done
}

# take shots
shotnow() {
  cd "${dir}" && xfce4-screenshooter --fullscreen --save "$file"
  notify_user
}

shot5() {
  countdown '5'
  sleep 1 && cd "${dir}" && xfce4-screenshooter --fullscreen --save "$file"
  notify_user
}

shotwin() {
  cd "${dir}" && xfce4-screenshooter --window --save "$file"
  notify_user
}

shotarea() {
  cd "${dir}" && xfce4-screenshooter --region --save "$file"
  notify_user
}

if [[ ! -d "$dir" ]]; then
  mkdir -p "$dir"
fi

if [[ "$1" == "--now" ]]; then
  shotnow
elif [[ "$1" == "--in5" ]]; then
  shot5
elif [[ "$1" == "--win" ]]; then
  shotwin
elif [[ "$1" == "--area" ]]; then
  shotarea
else
  echo -e "Available Options : --now --in5 --win --area"
fi

exit 0
