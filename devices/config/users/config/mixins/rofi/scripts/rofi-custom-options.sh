#!/usr/bin/env bash

echo -en "\x00prompt\x1f\n"

if [ "$*" = "Change BSPWM gaps" ]
then
  echo 16
  echo 32
  echo 64
  exit 0
fi

if [ "$*" = "Desktop 2 Booker" ]
then
  coproc (/etc/bspwm_desktop_2_booker.sh > /dev/null 2>&1)
  exit 0
fi

if [ "$*" = "Desktop 2 Tripper" ]
then
  coproc (/etc/bspwm_desktop_2_tripper.sh > /dev/null 2>&1)
  exit 0
fi

if [ "$*" = "Desktop 4" ]
then
  coproc (/etc/bspwm_desktop_4.sh > /dev/null 2>&1)
  exit 0
fi

if [[ -z "$@" ]]; then
  echo -en "Change BSPWM gaps\0icon\x1fterminal\n"
  echo -en "Desktop 2 Booker\0icon\x1fterminal\n"
  echo -en "Desktop 2 Tripper\0icon\x1fterminal\n"
  echo -en "Desktop 4\0icon\x1fterminal\n"
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
