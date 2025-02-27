#!/usr/bin/env bash

result=$(tofi-drun --config "$HOME/.config/tofi/one-line" --drun-launch=false)

if [[ -z "$result" ]]; then
  exit 0
fi

uwsm-app -- $result
