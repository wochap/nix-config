#!/usr/bin/env bash

if [[ -z "$@" ]]; then
  echo 16
  echo 32
  echo 64
else
  export BSPWM_WINDOW_GAP=$1
  killall -q polybar
  if [[ $1 == 16 ]]; then
    coproc (polybar main -r > /dev/null 2>&1)
  else
    coproc (polybar secondary -r > /dev/null 2>&1)
  fi
  bspc config window_gap $1
  exit 0
fi
