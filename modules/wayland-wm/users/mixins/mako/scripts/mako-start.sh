#!/usr/bin/env bash

CONFIG_FILES="$HOME/.config/mako/config"

mako &
trap "killall mako" EXIT

while true; do
  inotifywait -e create,modify $CONFIG_FILES
  makoctl reload
done

