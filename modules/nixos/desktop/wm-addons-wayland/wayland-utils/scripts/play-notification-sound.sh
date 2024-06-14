#!/usr/bin/env bash

declare -i throttle_by=1
cache_path="$HOME/.cache/"

debounce() {
  if [[ ! -f "$cache_path/executing" ]]; then
    touch "$cache_path/executing"
    "$@"
    retVal=$?
    {
      sleep $throttle_by
      if [[ -f "$cache_path/on-finish" ]]; then
        "$@"
        rm -f "$cache_path/on-finish"
      fi
      rm -f "$cache_path/executing"
    } &
    return $retVal
  elif [[ ! -f "$cache_path/on-finish" ]]; then
    touch "$cache_path/on-finish"
  fi
}

debounce paplay "$HOME/.local/share/assets/notification.flac"

wait $(jobs -p)
