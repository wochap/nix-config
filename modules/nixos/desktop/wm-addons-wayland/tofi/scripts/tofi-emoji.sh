#!/usr/bin/env bash

# file_path=$HOME/.local/share/tofi/emojis.txt
file_path=/home/gean/nix-config/modules/nixos/desktop/wm-addons-wayland/tofi/dotfiles/emojis.txt
options=$(cat "$file_path")
selected="$(echo -e "$options" |
  tofi \
    --prompt-text "emoji" \
    --config "$HOME/.config/tofi/one-line")"

if [[ -n "$selected" ]]; then
  echo -n "${selected:0:1}" | wl-copy
fi
