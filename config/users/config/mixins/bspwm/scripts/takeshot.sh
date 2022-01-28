#!/usr/bin/env bash
## Script to take screenshots with maim

time=$(date +%Y-%m-%d-%I-%M-%S)
geometry=$(xrandr | head -n1 | cut -d',' -f2 | tr -d '[:blank:],current')
dir="$(xdg-user-dir PICTURES)/Screenshots"
file="Screenshot_${time}_${geometry}.jpg"
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
  cd ${dir} && xfce4-screenshooter --fullscreen --clipboard --save "$file" && pinta ${dir}/"$file"
  notify_user
}

shot5() {
  countdown '5'
  sleep 1 && cd ${dir} && xfce4-screenshooter --fullscreen --clipboard --save "$file" && pinta ${dir}/"$file"
  notify_user
}

shot10() {
  countdown '10'
  sleep 1 && cd ${dir} && xfce4-screenshooter --fullscreen --clipboard --save "$file" && pinta ${dir}/"$file"
  notify_user
}

shotwin() {
  cd ${dir} && xfce4-screenshooter --window --clipboard --save "$file" && pinta ${dir}/"$file"
  notify_user
}

shotarea() {
  cd ${dir} && xfce4-screenshooter --region --clipboard --save "$file" && pinta ${dir}/"$file"
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
