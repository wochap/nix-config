#!/usr/bin/env bash

kitty_session="$(cat << EOF
launch zsh -c 'ncmpcpp'
launch zsh -c 'cava'
EOF
)"
echo "$kitty_session" | kitty --class kitty-ncmpcpp --session - &

