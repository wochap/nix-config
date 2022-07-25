#!/usr/bin/env bash

# source theme colors
. "/etc/scripts/theme-colors.sh"

time=$(date +%Y-%m-%d-%I-%M-%S)
dir="$(xdg-user-dir PICTURES)/Screenshots"
file="Screenshot_${time}.jpg"
EXPIRE_TIME=5000
dest="$dir/$file"

# notify
notify_user() {
  if [[ -e "$dest" ]]; then
    # TODO: copy to clipboard

    action=$(dunstify -t "$EXPIRE_TIME" --replace=699 -i "$dest" "Screen shooter" "Screenshot Saved" --action "default,Edit" --action "open,Open")
  else
    dunstify -t "$EXPIRE_TIME" --replace=699 "Screen shooter" "Screenshot Aborted."
    exit
  fi

  if [[ $action == "default" ]]; then
    swappy -f "$dest" -o "$dest" &
  elif [[ $action == "open" ]]; then
    xdg-open "$dest" &
  fi
}

# countdown
countdown() {
  for sec in $(seq $1 -1 1); do
    dunstify -t 1000 --replace=699 -i $dest "Taking shot in : $sec"
    sleep 1
  done
}

# take shots
shotnow() {
  cd ${dir} && grim - | swappy -f - -o "$file" -
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

shotarea() {
  area=$(slurp -d -b "${background}bf" -c "$primary")
  if [[ -z $area ]]; then
    notify_user
    exit
  fi
  grim -g "$area" "$dest"
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
else
  echo -e "Available Options : --now --in5 --area"
fi

exit 0

