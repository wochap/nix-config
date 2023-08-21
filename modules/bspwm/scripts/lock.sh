#!/usr/bin/env bash

greet=""
color="f8f8f2"
wrong_pass="Incorrect, Try Again"
font="FiraCode Nerd Font Mono"
background="$HOME/Pictures/backgrounds/lockscreen.jpg"

i3lock-color \
  --nofork \
  --ignore-empty-password \
  --indicator \
  --bar-indicator \
  --bar-base-width="10" \
  --bar-orientation=horizontal \
  --bar-color=282a36ff \
  --ringver-color=50fa7bff \
  --ringwrong-color=ff5555ff \
  --bshl-color=6272a4ff \
  --keyhl-color=bd93f9ff \
  --clock \
  --time-color=$color \
  --time-str="%H:%M:%S" \
  --time-font="$font" \
  --time-size=108 \
  --time-color=$color \
  --date-color=$color \
  --date-str="%A, %d %B" \
  --date-color=$color \
  --date-font="$font" \
  --date-size=27 \
  --verif-font="$font" \
  --verif-size=36 \
  --verif-text="$greet" \
  --verif-color=$color\
  --wrong-font="$font" \
  --wrong-size=36 \
  --wrong-text="$wrong_pass" \
  --wrong-color=$color \
  -i "$background"
