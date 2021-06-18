#!/usr/bin/env sh

function run {
  if ! pgrep $1 ;
    echo "$1 already running"
  then
    coproc ($@ > /dev/null 2>&1)
    echo "$1 started"
  fi
}

bspc desktop 2 -l monocle
bspc rule -a "kitty" -o desktop=^2
bspc desktop -f 2

run kitty --session /etc/kitty-session-booker.conf
