#!/usr/bin/env bash

file_path=$HOME/Sync/options
url='https://git.io/JXXO7'

if [ ! -f "$file_path" ]; then
  curl -sSL "$url" -o "$file_path"
fi

options=$(cat "$file_path")
selected="$(echo -e "$options" |
  tofi \
    --prompt-text "emoji" \
    --config "$HOME/.config/tofi/one-line")"

if [[ -n "$selected" ]]; then
  echo -n "${selected:0:1}" | wl-copy
fi
