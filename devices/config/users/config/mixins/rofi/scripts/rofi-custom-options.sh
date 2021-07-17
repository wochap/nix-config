#!/usr/bin/env bash

function stop {
  if ! pgrep $1 ;
    pgrep $1 | xargs kill
    while pgrep -u $UID -x $1 >/dev/null; do sleep 1; done
  then
    echo "$1 stopped"
  fi
}

function run {
  coproc ($@ > /dev/null 2>&1)
}

#Update rofi promt icon
echo -en "\x00prompt\x1f\n"

#Retrieve first selection
first_selection=$(cat /tmp/rofi-custom-options)

if [[ "$first_selection" && -z "$@" ]]
then
  first_selection=""
fi

#Clear first selection
echo "" > /tmp/rofi-custom-options

if [[ "$first_selection" == *"Change BSPWM gaps"* ]]
then
  stop polybar > /dev/null 2>&1
  bspc config window_gap $1
  bspc config top_padding $(($POLYBAR_HEIGHT + 25))
  coproc (polybar powermenu -q -r > /dev/null 2>&1)
  coproc (polybar workspaces -q -r > /dev/null 2>&1)
  coproc (polybar tray -q -r > /dev/null 2>&1)
  coproc (polybar right -q -r > /dev/null 2>&1)
  coproc (polybar xkeyboard -q -r > /dev/null 2>&1)
  coproc (polybar monocle-indicator -q -r > /dev/null 2>&1)
  exit 0
fi

if [[ "$*" == *"Workspace"* ]]
then
  focused_workspace=$(bspc query --desktops --desktop focused --names)
  workspace_selected=$(echo "$*" | awk -F\  '{print $2}')
  ws=$([ "$workspace_selected" == "current" ] && echo "$focused_workspace" || echo "$workspace_selected")

  if [[ "$first_selection" == *"Open nix-config"* ]]
  then
    bspc rule -a "kitty" -o desktop=^$ws
    bspc desktop -f $ws
    run kitty --session /etc/kitty-session-nix-config.conf
    exit 0
  fi

  if [[ "$first_selection" == *"Open booker project"* ]]
  then
    # bspc desktop $ws -l monocle
    bspc rule -a "kitty" -o desktop=^$ws
    bspc desktop -f $ws
    run kitty --session /etc/kitty-session-booker.conf
    exit 0
  fi

  if [[ "$first_selection" == *"Open tripper project"* ]]
  then
    # bspc desktop $ws -l monocle
    bspc rule -a "kitty" -o desktop=^$ws
    bspc desktop -f $ws
    run kitty --session /etc/kitty-session-tripper.conf
    exit 0
  fi
fi

if [[ "$*" = "Open nix-config" || "$*" = "Open booker project" || "$*" = "Open tripper project" ]]
then
  #Save selection
  echo "$*" > /tmp/rofi-custom-options

  #Show list label
  echo -en "\0markup-rows\x1ftrue\n"
  echo -en "\0message\x1f<b>Select workspace</b>\n"

  #Show options
  echo "Workspace current"
  workspaces=(2 3 F2 F3 F4)
  for w in ${workspaces[@]}
  do
    echo "Workspace $w"
  done

  exit 0
fi

if [ "$*" = "Change BSPWM gaps" ]
then
  #Save selection
  echo "$*" > /tmp/rofi-custom-options

  #Show list label
  echo -en "\0markup-rows\x1ftrue\n"
  echo -en "\0message\x1f<b>Select BSPWM gap size</b>\n"

  #Show options
  echo 0
  echo 16
  echo 32
  echo 64

  exit 0
fi

if [ "$*" = "Desktop 4" ]
then
  coproc (/etc/bspwm_desktop_4.sh > /dev/null 2>&1)
  exit 0
fi

if [[ -z "$@" ]]; then
  echo -en "Open booker project\0icon\x1fterminal\n"
  echo -en "Open tripper project\0icon\x1fterminal\n"
  echo -en "Open nix-config\0icon\x1fterminal\n"
  echo -en "Desktop 4\0icon\x1fterminal\n"
  echo -en "Change BSPWM gaps\0icon\x1fterminal\n"
else
  exit 0
fi
