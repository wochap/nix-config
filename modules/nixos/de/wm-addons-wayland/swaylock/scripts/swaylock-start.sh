#!/usr/bin/env bash

# source theme colors
. "/etc/scripts/theme-colors.sh"

swaylock \
  --daemonize \
  --scaling center \
  --color "#1E1E2E" \
  --clock \
  --indicator-idle-visible \
  --font "Iosevka NF" \
  --indicator-radius 100 \
  --indicator-thickness 10 \
  --ignore-empty-password \
  --ring-color ${selection:1} \
  --ring-ver-color ${primary:1} \
  --ring-wrong-color ${red:1} \
  --ring-clear-color ${orange:1} \
  --key-hl-color ${primary:1} \
  --text-color ${foreground:1} \
  --text-ver-color ${foreground:1} \
  --text-wrong-color ${foreground:1} \
  --text-clear-color ${foreground:1} \
  --text-caps-lock-color ${orange:1} \
  --line-uses-inside \
  --inside-color ${background:1} \
  --inside-ver-color ${background:1} \
  --inside-wrong-color ${background:1} \
  --inside-clear-color ${background:1} \
  --layout-bg ${background:1} \
  --layout-border-color ${background:1} \
  --layout-text-color ${foreground:1} \
  --separator-color 00000000 \
  --screenshots --effect-scale 0.5 --effect-blur 7x3 --effect-scale 2 \
  --show-failed-attempts
