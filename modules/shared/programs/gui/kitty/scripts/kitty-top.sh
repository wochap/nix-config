#!/usr/bin/env bash

uname=$(uname)

if [[ "$uname" == "Darwin" ]]; then
  kitty --title kitty-top -e btm
else
  # kitty --class kitty-top --title top -e htop
  kitty --class kitty-top --title top -e btm
fi

