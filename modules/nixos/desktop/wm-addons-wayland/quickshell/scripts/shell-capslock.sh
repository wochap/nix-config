#!/usr/bin/env bash

INPUT_PATH="platform-i8042-serio-0-event-kbd"

# check if any capslock led is on
check_capslock() {
  # HACK: wait for files to be updated
  sleep 0.1
  is_capslock_on=0
  for capslock_led_path in $(ls -al /sys/class/leds | grep capslock | awk '{print $(NF - 2)}'); do
    [ "$(cat "/sys/class/leds/$capslock_led_path/brightness")" -eq 1 ] && is_capslock_on=1
  done
  if [ "$is_capslock_on" -eq 1 ]; then
    printf -- 'true\n'
  else
    printf -- 'false\n'
  fi
}

check_capslock

# NOTE: this one generates a huge number of wakeup
# but works on all systems
# libinput debug-events --show-keycodes | grep --line-buffered CAPSLOCK | grep --line-buffered pressed | while IFS= read -r line; do
#   check_capslock
# done

# NOTE: specific to glegion
evemu-record "/dev/input/by-path/$INPUT_PATH" | grep --line-buffered LED_CAPSL | while IFS= read -r line; do
  check_capslock
done
