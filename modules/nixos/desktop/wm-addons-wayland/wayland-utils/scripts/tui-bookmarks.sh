#!/usr/bin/env bash

echo "$@" | xargs -I {} kitty --single-instance --class tui-bookmarks --title wobook -o window_padding_width=0 -o close_on_child_death=yes -e sh -c "wobook-fzf {}"
