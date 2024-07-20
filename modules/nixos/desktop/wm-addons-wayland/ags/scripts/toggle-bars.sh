#!/usr/bin/env bash

mons_count=$(wlr-randr --json | jq 'length')

for ((i = 0; i < mons_count; i++)); do
  ags --toggle-window "bar-$i"
done
