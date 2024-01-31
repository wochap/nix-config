#!/usr/bin/env sh

set -xe

if [[ $# == 0 ]]; then
  kitty --class kitty-neomutt --title neomutt -e \
    zsh -c "export DISABLE_ZSH_AUTOSTART=1 && neomutt"
else
  kitty --class kitty-neomutt --title neomutt -e \
    zsh -c "export DISABLE_ZSH_AUTOSTART=1 && neomutt \"$@\""
fi
