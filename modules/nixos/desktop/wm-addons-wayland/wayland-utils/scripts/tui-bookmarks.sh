#!/usr/bin/env bash

echo "$@" | xargs -I {} kitty --class tui-bookmarks --title buku -o window_padding_width=0 -o close_on_child_death=yes -e sh -c "buku-fzf {}"
