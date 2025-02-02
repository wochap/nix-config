#!/usr/bin/env bash

if [ "$1" = "--on" ]; then
  if [ "$XDG_SESSION_DESKTOP" = "hyprland" ]; then
    hyprctl dispatch dpms on
  elif [ "$XDG_SESSION_DESKTOP" = "dwl" ]; then
    wlopm --on "*"
  fi
elif [ "$1" = "--off" ]; then
  if [ "$XDG_SESSION_DESKTOP" = "hyprland" ]; then
    hyprctl dispatch dpms off
  elif [ "$XDG_SESSION_DESKTOP" = "dwl" ]; then
    wlopm --off "*"
  fi
fi
