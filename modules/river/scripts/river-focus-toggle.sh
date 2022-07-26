#!/usr/bin/env bash

PROG=$(basename $0)
TEMP=$(getopt --options sth --longoptions toggle-scratchpad,send-to-origin,help -- "$@") || exit 1
eval set -- "$TEMP"
shift
target="$1"
runstring="$2"
echo "$PROG: target='$target' runstring='$runstring'" >&2

if [[ -z "$runstring" ]]; then
  exit
fi

# TODO:
# https://git.sr.ht/~leon_plickat/lswt

echo "hee"
