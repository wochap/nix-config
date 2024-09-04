#!/usr/bin/env bash

kitty --class tui-notes --title zk -o window_padding_width=0 -e nvim zk +'cd ~/Sync/zk' +":lua require('persistence').load()"
