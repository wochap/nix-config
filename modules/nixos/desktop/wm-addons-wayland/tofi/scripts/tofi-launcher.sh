#!/usr/bin/env bash

result=$(tofi-drun --config "$HOME/.config/tofi/one-line" --drun-launch=false)

if [[ -z "$result" ]]; then
  exit 0
fi

if [[ "$1" == "--uwsm" ]]; then
  uwsm-app -- $result
else
  echo $result | xargs -I {} sh -c {}
fi
