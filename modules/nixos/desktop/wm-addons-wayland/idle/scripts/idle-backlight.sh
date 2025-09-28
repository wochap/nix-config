#!/usr/bin/env bash

if [ "$1" = "--on" ]; then
  # set the power mode of the output to on
  if [ "$XDG_SESSION_DESKTOP" = "Hyprland" ]; then
    hyprctl dispatch dpms on
  fi

  brightnessctl --restore

  # increase brightness if it is too low
  DEVICES=$(find /sys/class/backlight -type l -printf "%f\n")
  for device in $DEVICES; do
    val=$(brightnessctl --device "$device" get)
    max=$(brightnessctl --device "$device" max)
    percentage=$(echo "($val / $max) * 100" | bc -l)
    is_less_than_10=$(echo "$percentage < 10" | bc -l)
    if [ "$is_less_than_10" -eq 1 ]; then
      brightnessctl --device "$device" set "10%"
    fi
  done
elif [ "$1" = "--off" ]; then
  is_dpms_off=$(hyprctl monitors -j | jq 'any(.[]; .dpmsStatus? == false)')

  if [[ "$is_dpms_off" == "true" ]]; then
    # backlight already off
    return 0
  fi

  brightnessctl --save

  if [[ -n "$(pgrep hyprlock)" ]]; then
    # decrease brightness to zero
    backlight "0%"

    # set the power mode of the output to off
    if [ "$XDG_SESSION_DESKTOP" = "Hyprland" ]; then
      hyprctl dispatch dpms off
    fi
  else
    # decrease brightness to zero
    chayang -d 5 && backlight "0%"
    # set the power mode of the output to off
    # NOTE: turning dpms off before running hyprlock
    # will cause hyprlock to crash
    # if [ "$XDG_SESSION_DESKTOP" = "Hyprland" ]; then
    #   hyprctl dispatch dpms off
    # fi
  fi
fi
