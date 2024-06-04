#!/usr/bin/env bash

echo "$@" | xargs -I {} kitty --class tui-bookmark --title buku -o close_on_child_death=yes -e sh -c "buku-fzf {}"
