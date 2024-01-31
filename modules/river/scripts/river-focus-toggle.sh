#!/usr/bin/env bash

PROG=$(basename $0)
TEMP=$(getopt --options sth --longoptions toggle-scratchpad,send-to-origin,help -- "$@") || exit 1
eval set -- "$TEMP"
shift
target="$1"
runstring="$2"
tag="$3" # e.g. $((1 << 31))
echo "$PROG: target='$target' runstring='$runstring'" >&2

if [[ -z "$runstring" ]]; then
  exit
fi

# tag where the view lives
riverctl rule-del tag -app-id "$target"
riverctl rule-add tag -app-id "$target" "$tag"
riverctl toggle-focused-tags "$tag"
wlrctl window focus "$target" || riverctl spawn "$runstring"

# TODO: check if it is running
# if running move to scratchpad
# if not, open or toggle visibility/sticky
# https://gitlab.com/snakedye/ristate
# https://git.sr.ht/~leon_plickat/lswt
# https://git.sr.ht/~brocellous/wlrctl
# https://github.com/riverwm/river/issues/350
# riverctl spawn "$runstring"

