#!/usr/bin/env bash

if [[ "$1" == "--select" ]]; then
  selected=$(buku -p -f 4 | fzf --preview "buku --nostdin -p {1}" --reverse --preview-window=wrap | cut -f 2)

  if [[ -n "$selected" ]]; then
    echo -n "$selected" | wl-copy
  fi
elif [[ "$1" == "--add" ]]; then
  # https://github.com/jarun/buku/issues/837
  buku --write
elif [[ "$1" == "--edit" ]]; then
  while true; do
    selected=$(buku -p -f 4 | fzf --preview "buku --nostdin -p {1}" --reverse --preview-window=wrap | cut -f 1)

    if [[ -n "$selected" ]]; then
      buku --write "$selected"
    fi

    read -r -n 1 -p "Do you want to continue editing? (y/n) " yn
    case $yn in
    [yY])
      printf "\n"
      ;;
    *)
      exit 0
      ;;
    esac
  done
else
  echo -e "Available Options : --select --add --edit"
fi

exit 0
