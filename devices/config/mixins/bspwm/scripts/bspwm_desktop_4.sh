#!/usr/bin/env sh

function stop {
  if ! pgrep $1 ;
    pgrep $1 | xargs kill
    while pgrep -u $UID -x $1 >/dev/null; do sleep 1; done
  then
    echo "$1 stopped"
  fi
}

function run {
  if ! pgrep $1 ;
    stop $1
  then
    coproc ($@ > /dev/null 2>&1)
    echo "$1 started"
  fi
}

function removeReceptacles {
  for win in $(bspc query -N -n .leaf.\!window) ; do bspc node $win -k ; done ;
}

removeReceptacles

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
bspc rule -a "Evolution" -o node=@4:/2/1
bspc rule -a "Gnome-todo" -o node=@4:/2/2/1
bspc rule -a "Org.gnome.clocks" -o node=@4:/2/2/2

run slack -s
run simplenote
run gnome-todo
run gnome-clocks
run evolution
