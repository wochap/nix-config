#!/usr/bin/env bash

IN_OBSIDIAN=true kitty --class tui-notes-obsidian --title obsidian -o window_padding_width=0 -e nvim +'cd ~/Sync/obsidian/utp'
