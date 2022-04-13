#!/usr/bin/env bash

uname=$(uname)

if [[ "$uname" == "Darwin" ]]; then
  kitty --title kitty-scratch --listen-on "unix:/tmp/kitty_scratch"
else
  kitty --class kitty-scratch --listen-on "unix:/tmp/kitty_scratch"
fi

