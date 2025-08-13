#!/usr/bin/env bash

function print_scheme() {
  scheme=$1
  if [[ "$scheme" == "'prefer-dark'" ]]; then
    echo "dark"
  elif [[ "$scheme" == "'prefer-light'" || "$scheme" == "'default'" ]]; then
    echo "light"
  fi
}

DCONF_KEY="/org/gnome/desktop/interface/color-scheme"

if [[ "$1" == "print" ]]; then
  last_scheme=$(dconf read "$DCONF_KEY")
  print_scheme "$last_scheme"
elif [[ "$1" == "watch" ]]; then
  last_scheme=$(dconf read "$DCONF_KEY")
  print_scheme "$last_scheme"

  dconf watch "$DCONF_KEY" |
    while read -r change; do
      current_scheme=$(dconf read "$DCONF_KEY")
      if [[ "$current_scheme" == "$last_scheme" ]]; then
        continue
      fi
      last_scheme="$current_scheme"
      print_scheme "$current_scheme"
    done
else
  echo "Usage: $0 {print|watch}"
  exit 1
fi
