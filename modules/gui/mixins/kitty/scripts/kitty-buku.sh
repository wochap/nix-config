#!/usr/bin/env bash


if [[ "$1" == "--select" ]]; then
  kitty --class kitty-buku --title buku -o close_on_child_death=yes -e "buku-fzf --select"
elif [[ "$1" == "--add" ]]; then
  kitty --class kitty-buku --title buku -o close_on_child_death=yes -e "buku-fzf --add"
elif [[ "$1" == "--edit" ]]; then
  kitty --class kitty-buku --title buku -o close_on_child_death=yes -e "buku-fzf --edit"
else
  echo -e "Available Options : --select --add --edit"
fi

exit 0
