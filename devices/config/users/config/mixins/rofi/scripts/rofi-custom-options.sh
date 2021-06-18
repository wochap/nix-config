#!/usr/bin/env bash

function run {
  coproc ($@ > /dev/null 2>&1)
}

echo -en "\x00prompt\x1f\n"

if [[ "$*" == *"Workspace"* ]]
then
  workspace=$(echo "$*" | awk -F\  '{print $2}')
  bspc rule -a "kitty" -o desktop=^$workspace
  run kitty --session /etc/kitty-session-nix-config.conf
  bspc desktop -f $workspace
  exit 0
fi

if [ "$*" = "Open nix-config" ]
then
  workspaces=(2 3 6 7 8)
  for w in ${workspaces[@]}
  do
    echo -en "\0markup-rows\x1ftrue\n"
    echo -en "\0message\x1f<b>Open nix-config in</b>\n"
    echo "Workspace $w"
  done
  exit 0
fi

if [ "$*" = "Change BSPWM gaps" ]
then
  echo -en "\0markup-rows\x1ftrue\n"
  echo -en "\0message\x1f<b>Select BSPWM gap size</b>\n"
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
  echo -en "Open nix-config\0icon\x1fterminal\n"
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
