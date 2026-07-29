#!/usr/bin/env bash

kitty_session="$(
  cat <<EOF
launch zsh -c 'rmpc'
EOF
)"
echo "$kitty_session" | kitty --single-instance --class tui-music --session - &
