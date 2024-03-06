#!/usr/bin/env bash

uname=$(uname)

if [[ "$uname" == "Darwin" ]]; then
  kitty --title kitty-newsboat -e newsboat
else
  kitty --class kitty-newsboat --title newsboat -e newsboat
fi

