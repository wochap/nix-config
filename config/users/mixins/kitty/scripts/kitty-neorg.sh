#!/usr/bin/env bash

uname=$(uname)

if [[ "$uname" == "Darwin" ]]; then
  kitty --title kitty-neorg -e nvim +'cd ~/Sync/neorg' +'NeorgStart'
else
  kitty --class kitty-neorg --title neorg -e nvim +'cd ~/Sync/neorg' +'NeorgStart'
fi

