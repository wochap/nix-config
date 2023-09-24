#!/usr/bin/env bash

uname=$(uname)

if [[ "$uname" == "Darwin" ]]; then
  kitty --title kitty-neorg -o window_padding_width=0 -e nvim +'cd ~/Sync/neorg' +'Neorg workspace home'
else
  kitty --class kitty-neorg --title neorg -o window_padding_width=0 -e nvim +'cd ~/Sync/neorg'
fi
