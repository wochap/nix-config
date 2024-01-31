#!/usr/bin/env bash

declare -i throttle_by=1

debounce() {
  if [[ ! -f ./executing ]]; then
    touch ./executing
    "$@"
    retVal=$?
    {
      sleep $throttle_by
      if [[ -f ./on-finish ]]; then
        "$@"
        rm -f ./on-finish
      fi
      rm -f ./executing
    } &
    return $retVal
  elif [[ ! -f ./on-finish ]]; then
    touch ./on-finish
  fi
}

debounce paplay "$HOME/.local/share/assets/notification.flac"

wait $(jobs -p)
