#!/usr/bin/env bash

# This script will randomly go through the files of a directory, setting it
# up as the wallpaper at regular intervals
#
# NOTE: this script is in bash (not posix shell), because the RANDOM variable
# we use is not defined in posix

backgrounds_path="${HOME}/Pictures/backgrounds/"
interval=300 # seconds, 5 minutes by default
oneshot=""

# Parse command line options
while [ "$#" -gt 0 ]; do
  case "$1" in
  --oneshot|-o)
    oneshot=true
    shift
    ;;
  --interval=*)
    interval="${1#*=}"
    shift
    ;;
  *)
    backgrounds_path="$1"
    shift
    ;;
  esac
done

if [[ ! -d $backgrounds_path ]]; then
  echo -e "Usage:
  $0 [option...] <dir containing images>/"
  echo -e "Available Options: --oneshot --interval=<seconds>"
  exit 1
fi

while true; do
  find "$backgrounds_path" |
    while read -r img; do
      echo "$((RANDOM % 1000)):$img"
    done |
    sort -n | cut -d':' -f2- |
    while read -r img; do
      swww img "$img"
      if [[ $oneshot ]]; then
        exit 0
      fi
      sleep "$interval"
    done
  if [[ $oneshot ]]; then
    exit 0
  fi
done
