#!/usr/bin/env bash

clear_db() {
  cliphist wipe
}

file_uri_to_path() {
  local encoded="${1#file://}"
  local decoded=""
  local byte

  # Accept both canonical file:///home/... URIs and legacy file://home/...
  # entries produced by helpers that concatenate "file:/" with an absolute path.
  if [[ "$encoded" != /* ]]; then
    encoded="/$encoded"
  fi

  while [[ "$encoded" =~ ^([^%]*)%([[:xdigit:]]{2})(.*)$ ]]; do
    decoded+="${BASH_REMATCH[1]}"
    printf -v byte '%b' "\\x${BASH_REMATCH[2]}"
    decoded+="$byte"
    encoded="${BASH_REMATCH[3]}"
  done

  printf '%s%s' "$decoded" "$encoded"
}

copy_selection() {
  local selected="$1"
  local path
  copied_file=0

  case "$selected" in
  file://*)
    path="$(file_uri_to_path "$selected")"
    ;;
  /*)
    path="$selected"
    ;;
  esac

  if [[ -n "$path" && "$path" != *$'\n'* && -e "$path" ]]; then
    shotclip -- "$(realpath -- "$path")" || return
    copied_file=1
  else
    printf '%s' "$selected" | wl-copy --trim-newline --type text/plain || return
  fi

  printf '%s' "$selected" | wl-copy --primary --trim-newline --type text/plain
}

init() {
  clear_db
  killall wl-paste
  # killall wl-clip-persist
  # TODO: wait for https://github.com/Linus789/wl-clip-persist/issues/6
  # wl-clip-persist --clipboard regular &
  wl-paste --type text --watch cliphist store --primary
}

menu() {
  list=$(cliphist -preview-width 250 list |
    sort -k 2 -u | # sort by 2 field to the end of line and output only unique lines
    sort -nr)      # sort numerically in reverse
  list_count=$(if [[ -z "$list" ]]; then echo 0; else echo "$list" | wc -l; fi)
  num_results=$(if [[ "$list_count" -gt 10 ]]; then echo 10; else echo "$list_count"; fi)
  height=$(if [[ "$num_results" -gt 0 ]]; then echo "scale=0; ($num_results * 29.20) + 11 + 40" | bc -l | awk '{print int($1+0.5)}'; else echo 40; fi)
  selected_entry=$(echo "$list" |
    tofi \
      --height "$height" \
      --num-results "$num_results" \
      --prompt-text "clipboard" \
      --config "$HOME/.config/tofi/multi-line")
  selected=$(printf '%s' "$selected_entry" | cliphist decode)

  if [ -n "$selected" ]; then
    if copy_selection "$selected"; then
      if ((copied_file)); then
        printf '%s' "$selected_entry" | cliphist delete
      fi
    fi
  fi
}

if [[ "$1" == "--start" ]]; then
  init
elif [[ "$1" == "--menu" ]]; then
  menu
elif [[ "$1" == "--clear" ]]; then
  clear_db
else
  echo -e "Available Options : --start --menu --clear"
fi

exit 0
