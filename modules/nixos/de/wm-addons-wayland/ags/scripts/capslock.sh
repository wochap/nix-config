#!/usr/bin/env bash

LOCKED="󰌎"
UNLOCKED=""

# check if any capslock led is on
check_capslock() {
  is_capslock_on=0
  for capslock_led_path in $(ls -al /sys/class/leds | grep capslock | awk '{print $(NF - 2)}'); do
    [ "$(cat "/sys/class/leds/$capslock_led_path/brightness")" -eq 1 ] && is_capslock_on=1
  done
  if [ "$is_capslock_on" -eq 1 ]; then
    printf -- '{"text":"%s","class":"locked"}\n' "$LOCKED"
  else
    printf -- '{"text":"%s","class":"unlocked"}\n' "$UNLOCKED"
  fi
}

check_capslock
libinput debug-events --show-keycodes | grep --line-buffered CAPSLOCK | grep --line-buffered pressed | while IFS= read -r line; do
  check_capslock
done
