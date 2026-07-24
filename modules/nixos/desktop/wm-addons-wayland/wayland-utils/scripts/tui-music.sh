#!/usr/bin/env bash

kitty_session="$(
  cat <<EOF
launch zsh -c 'rmpc'
EOF
)"
echo "$kitty_session" | kitty --class tui-music --session - &
