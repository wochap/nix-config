#!/usr/bin/env bash

IN_ZK=true kitty --class tui-notes --title zk -o window_padding_width=0 -e nvim +'cd ~/Sync/zk' +":lua require('persistence').load()"
