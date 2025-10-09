#!/usr/bin/env bash

# This script controls the system audio volume using wpctl.
# It's updated to handle a special argument format: N%[+-]
# N%+ : Rounds the volume UP to the next multiple of N.
#       e.g., if volume is 7% and you run with 5%+, it goes to 10%.
# N%- : Rounds the volume DOWN to the previous multiple of N.
#       e.g., if volume is 7% and you run with 5%-, it goes to 5%.

# Function to print the current volume as an integer percentage (0-100).
# wpctl returns a decimal (e.g., 0.75), so we convert it.
print_current_volume_percent() {
  local id="$1"

  # The output from wpctl is like "Volume: 0.75" or "Volume: 1.00 [MUTED]".
  # We extract the numeric value.
  local volume_decimal
  volume_decimal=$(wpctl get-volume "$id" | awk '{print $2}')

  # Use awk to handle floating-point math and convert to a whole number percentage.
  local volume_percent
  volume_percent=$(awk -v vol="$volume_decimal" 'BEGIN { printf "%.0f", vol * 100 }')

  echo "$volume_percent"
}

change_volume() {
  local id="$1"
  local vol="$2"

  if [[ "$id" == "@DEFAULT_SINK@" ]]; then
    # First, if the sink is muted, unmute it before changing the volume.
    if [[ "$(pactl get-sink-mute "$id")" == "Mute: yes" ]]; then
      wpctl set-mute "$id" toggle
    fi
  fi

  if [[ "$id" == "@DEFAULT_SOURCE@" ]]; then
    # First, if the source is muted, unmute it before changing the volume.
    if [[ "$(pactl get-source-mute "$id")" == "Mute: yes" ]]; then
      wpctl set-mute "$id" toggle
    fi
  fi

  # Check if the volume argument matches the new "N%+" or "N%-" format.
  if [[ "$vol" =~ ^([0-9]+)%([+-])$ ]]; then
    # The regex matches and captures the parts of the argument.
    # BASH_REMATCH[1] will be the number (N).
    # BASH_REMATCH[2] will be the operator (+ or -).
    local multiplier="${BASH_REMATCH[1]}"
    local operator="${BASH_REMATCH[2]}"

    # Get the current volume as an integer (e.g., 75).
    local current_vol
    current_vol=$(print_current_volume_percent "$id")

    # Avoid division by zero if the multiplier is 0.
    if ((multiplier == 0)); then
      echo "Error: Multiplier cannot be zero." >&2
      exit 1
    fi

    local new_vol
    if [[ "$operator" == "+" ]]; then
      # --- INCREMENT LOGIC ---
      # Calculate the next multiple of N.
      # Bash integer division automatically floors the result.
      # Example (N=5): current=7 -> (7/5 + 1)*5 -> (1 + 1)*5 -> 10
      # Example (N=5): current=5 -> (5/5 + 1)*5 -> (1 + 1)*5 -> 10
      new_vol=$(((current_vol / multiplier + 1) * multiplier))
    elif [[ "$operator" == "-" ]]; then
      # --- DECREMENT LOGIC ---
      # Calculate the previous multiple of N.
      # We subtract 1 to handle cases where the volume is already a multiple.
      # Example (N=5): current=7 -> ((7-1)/5)*5 -> (6/5)*5 -> 1*5 -> 5
      # Example (N=5): current=10 -> ((10-1)/5)*5 -> (9/5)*5 -> 1*5 -> 5
      new_vol=$(((current_vol - 1) / multiplier * multiplier))

      # Ensure the volume doesn't go below 0.
      if ((new_vol < 0)); then
        new_vol=0
      fi
    fi

    # Set the newly calculated volume.
    wpctl set-volume -l 2 "$id" "${new_vol}%"
  else
    # If the argument doesn't match the new format, fall back to the original behavior.
    # This allows standard commands like "5%+" or "50%" to still work.
    wpctl set-volume -l 2 "$id" "$vol"
  fi
}

case "$1" in
--volume-input)
  change_volume "@DEFAULT_SOURCE@" "$2"
  ;;
--volume-output)
  change_volume "@DEFAULT_SINK@" "$2"
  ;;
*)
  echo "Usage: $0 [--volume-input <value> | --volume-output <value>]" >&2
  exit 1
  ;;
esac
