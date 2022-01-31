#!/usr/bin/env bash

function stop {
  if pgrep "$1"; then
    pids=$(pgrep "$1")
    pgrep "$1" | xargs kill
    for pid in ${pids[*]}; do
      while pgrep -P "$pid" -x "$1" >/dev/null; do sleep 0.5; done
    done
  fi
  echo "$1 stopped"
}

function run {
  if pgrep "$1"; then
    stop "$1"
  fi
  "$@" >/dev/null 2>&1 &
  echo "$1 started"
}

function removeEmptyReceptacles {
  for win in $(bspc query -N -n .leaf.\!window); do bspc node "$win" -k; done
}

removeEmptyReceptacles

stop slack
stop simplenote
stop gnome-todo
stop gnome-clocks
stop evolution

# source: https://www.reddit.com/r/bspwm/comments/ggtwxa/guide_to_creating_startup_layout_using_receptacles/
bspc node @4:/ -i
bspc node @4:/ -p east -i
bspc node @4:/1 -p south -i
bspc node @4:/2 -p south -i
bspc node @4:/2/2 -p east -i
bspc rule -a "Slack" -o node=@4:/1/1
bspc rule -a "Simplenote" -o node=@4:/1/2
bspc rule -a ".evolution-wrapped_" -o node=@4:/2/1
bspc rule -a "Gnome-todo" -o node=@4:/2/2/1
bspc rule -a "Org.gnome.clocks" -o node=@4:/2/2/2
bspc desktop -f 4

run slack
run simplenote
run gnome-todo
run gnome-clocks
run evolution
