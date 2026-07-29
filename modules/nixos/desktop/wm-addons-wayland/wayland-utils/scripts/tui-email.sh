#!/usr/bin/env bash

set -xe

if [[ $# == 0 ]]; then
  kitty --single-instance --class tui-email --title neomutt -e sh -c neomutt
else
  echo "$@" | xargs -I {} kitty --single-instance --class tui-email --title neomutt -e sh -c "neomutt {}"
fi
