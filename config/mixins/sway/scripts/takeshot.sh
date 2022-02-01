#!/usr/bin/env bash
## Script to take screenshots with maim

time=$(date +%Y-%m-%d-%I-%M-%S)
dir="$(xdg-user-dir PICTURES)/Screenshots"
file="Screenshot_${time}.jpg"
EXPIRE_TIME=5000

# notify
notify_user() {
  if [[ -e "$dir/$file" ]]; then
    dunstify -t "$EXPIRE_TIME" --replace=699 -i $dir/$file "Screen shooter" "Screenshot Saved"
  else
    dunstify -t "$EXPIRE_TIME" --replace=699 -i $dir/$file "Screen shooter" "Screenshot Deleted."
  fi
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

shotwin() {
  cd ${dir} && grim -g "$(swaymsg -t get_tree | jq -r '.. | select(.pid? and .visible?) | .rect | "\(.x),\(.y) \(.width)x\(.height)"' | slurp)" - | swappy -f - -o "$file" -
  notify_user
}

shotarea() {
  cd ${dir} && grim -g "$(slurp)" - | swappy -f - -o "$file" -
  notify_user
}

if [[ ! -d "$dir" ]]; then
  mkdir -p "$dir"
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

