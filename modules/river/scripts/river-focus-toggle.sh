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

# TODO: check if it is running
# if running move to scratchpad
# if not, open or toggle visibility/sticky
# https://git.sr.ht/~leon_plickat/lswt
# https://git.sr.ht/~brocellous/wlrctl
# https://github.com/riverwm/river/issues/350
riverctl spawn "$runstring"

