#!/usr/bin/env bash

uname=$(uname)

if [[ "$uname" == "Darwin" ]]; then
  kitty --title kitty-neorg -e nvim +'cd ~/Sync/neorg' +'Neorg workspace home'
else
  kitty --class kitty-neorg --title neorg -e nvim +'cd ~/Sync/neorg'
fi
