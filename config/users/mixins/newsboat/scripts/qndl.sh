#!/usr/bin/env bash

# $1 is a url; $2 is a command
[ -z "$1" ] && exit
base="$(basename "$1")"
notify-send "⏳ Queuing $base..."
cmd="$2"
[ -z "$cmd" ] && cmd="youtube-dl --add-metadata -ic"
idnum="$(tsp $cmd "$1")"
realname="$(echo "$base" | sed "s/?\(source\|dest\).*//;s/%20/ /g")"
tsp -D "$idnum" mv "$base" "$realname"
tsp -D "$idnum" notify-send "👍 $realname done."