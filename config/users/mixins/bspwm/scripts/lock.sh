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
  --bar-pos="1070" \
  --bar-base-width="10" \
  --bar-orientation=horizontal \
  --bar-color=151515 \
  --ringver-color=$color \
  --ringwrong-color=$color \
  --bshl-color=$color \
  --keyhl-color=$color \
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
  -i $background
