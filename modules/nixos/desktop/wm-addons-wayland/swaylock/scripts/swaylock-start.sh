#!/usr/bin/env bash

# source theme colors
source "$HOME/.config/scripts/theme-colors.sh"

args=""
if [ "$BACKGROUND" = "1" ]; then
  args="--image $HOME/Pictures/backgrounds/swaylock.jpg"
else
  args="--screenshots --effect-scale 0.5 --effect-blur 7x3 --effect-scale 2"
fi

echo "$args" | xargs swaylock \
  --daemonize \
  --scaling center \
  --color ${background:1} \
  --clock \
  --indicator-idle-visible \
  --font "Iosevka NF" \
  --indicator-radius 100 \
  --indicator-thickness 10 \
  --ignore-empty-password \
  --ring-color ${border:1} \
  --ring-ver-color ${primary:1} \
  --ring-wrong-color ${red:1} \
  --ring-clear-color ${peach:1} \
  --key-hl-color ${primary:1} \
  --text-color ${text:1} \
  --text-ver-color ${text:1} \
  --text-wrong-color ${text:1} \
  --text-clear-color ${text:1} \
  --text-caps-lock-color ${peach:1} \
  --line-uses-inside \
  --inside-color ${background:1} \
  --inside-ver-color ${background:1} \
  --inside-wrong-color ${background:1} \
  --inside-clear-color ${background:1} \
  --layout-bg ${background:1} \
  --layout-border-color ${background:1} \
  --layout-text-color ${text:1} \
  --separator-color 00000000 \
  --show-failed-attempts
