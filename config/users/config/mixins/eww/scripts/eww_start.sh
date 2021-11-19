#!/usr/bin/env sh

pactl subscribe | grep --line-buffered "sink" | xargs -d "\n" -n1 /etc/scripts/eww_vol_listen.sh &
