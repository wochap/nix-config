#!/usr/bin/env bash

set -xe

if [[ $# == 0 ]]; then
  kitty --class tui-email --title neomutt -e sh -c neomutt
else
  echo "$@" | xargs -I {} kitty --class tui-email --title neomutt -e sh -c "neomutt {}"
fi
