#!/usr/bin/env bash

BSPWM_DESKTOPS=(1 2 3 4 F1 F2 F3 F4)

mfrom="$1"
mto="$2"

for di in "${!BSPWM_DESKTOPS[@]}"; do
  desktop="${BSPWM_DESKTOPS[$di]}"
  nodes=($(bspc query --nodes --node .window --desktop "$mfrom:^$di"))

  for ni in "${!nodes[@]}"; do
    node=${nodes[$ni]}
    echo $node
    bspc node $node --to-desktop "$mto:^$di"
  done
done
