#!/usr/bin/env bash

hidden_windows=$(bspc query -N -n .hidden.local.window | wc -l)
echo "$hidden_windows"
