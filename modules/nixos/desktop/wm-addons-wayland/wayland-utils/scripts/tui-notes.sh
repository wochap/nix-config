#!/usr/bin/env bash

kitty --class tui-notes --title neorg -o window_padding_width=0 -e nvim neorg +'cd ~/Sync/neorg' +'Neorg workspace home' +":lua require('persistence').load()"
