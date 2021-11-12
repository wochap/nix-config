#!/usr/bin/env bash

active_window_number=$(bspc query -N -n .window -d focused | grep -n $(bspc query -N -n) | cut -f1 -d:)
if [[ -z "${active_window_number// }" ]]; then
  active_window_number="0"
fi

echo "($active_window_number/$(bspc query -N -n .window -d focused | wc -l))"
