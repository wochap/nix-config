#!/usr/bin/env bash

kitty --class tui-notes --title neorg -o window_padding_width=0 -e nvim neorg +'cd ~/Sync/neorg' +":lua require('persistence').load()" +'Neorg workspace home'
