#!/usr/bin/env bash

echo "($(bspc query -N -n .window -d focused | grep -n $(bspc query -N -n) | cut -f1 -d:)/$(bspc query -N -n .window -d focused | wc -l))"
