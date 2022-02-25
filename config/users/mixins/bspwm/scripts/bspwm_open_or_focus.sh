#!/usr/bin/env bash

class="$1"
runstring="$2"

id=$(xdo id -N "$class")

if [ -z "${id}" ]; then
  exec "$runstring" >/dev/null 2>&1 &
else
  while read -r instance; do
    bspc node "${instance}" --focus
  done <<<"${id}"
fi
