#!/usr/bin/env bash

set -xe

if [[ $# == 0 ]]; then
  kitty --class kitty-neomutt --title neomutt -e sh -c neomutt
else
  echo "$@" | xargs -I {} kitty --class kitty-neomutt --title neomutt -e sh -c "neomutt {}"
fi
