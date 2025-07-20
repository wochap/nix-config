#!/usr/bin/env bash

# NOTE: requirements: yq upower

CONFIG_FILE="$HOME/.config/batty/config.yaml"
LOCK_DIR="/tmp/batty_locks"
STATE_FILE="$LOCK_DIR/last_state.txt" # Stores the last known state (charging/discharging)

# Ensure config file exists
if [ ! -f "$CONFIG_FILE" ]; then
  echo "Error: Config file not found at $CONFIG_FILE" >&2
  exit 1
fi

# Create lock directory
mkdir -p "$LOCK_DIR"

# Main Logic Function
process_state() {
  # Get the first battery found by upower
  local battery
  battery=$(upower -e | grep 'BAT' | head -n 1)
  if [ -z "$battery" ]; then
    # No battery found, do nothing.
    return
  fi

  # Parse state and percentage from upower
  local state
  local percentage
  state=$(upower -i "$battery" | grep -E '^\s*state:' | awk '{print $2}')
  percentage=$(upower -i "$battery" | grep -E '^\s*percentage:' | awk '{print $2}' | sed 's/%//')

  # Normalize state for the config file (e.g., fully-charged -> charging)
  local normalized_state
  if [[ "$state" == "discharging" ]]; then
    normalized_state="discharging"
  elif [[ "$state" == "charging" || "$state" == "fully-charged" || "$state" == "pending-charge" ]]; then
    normalized_state="charging"
  else
    # Unknown state, do nothing for this cycle
    return
  fi

  # State Change Detection
  # If the state has changed (e.g., plugged in/unplugged), clear all locks
  local last_state
  last_state=$(cat "$STATE_FILE" 2>/dev/null)
  if [[ "$normalized_state" != "$last_state" ]]; then
    echo "State changed from '$last_state' to '$normalized_state'. Resetting notifications."
    rm -f "$LOCK_DIR"/*.lock
    echo "$normalized_state" >"$STATE_FILE"
  fi

  # Rule Processing
  # Get all percentage thresholds for the current state from the YAML file
  local thresholds
  thresholds=$(yq -r ".$normalized_state | keys | .[]" "$CONFIG_FILE")

  for threshold in $thresholds; do
    local lock_file="$LOCK_DIR/${normalized_state}_${threshold}.lock"
    local condition_met=false

    # Check if the condition is met for the current state
    if [[ "$normalized_state" == "discharging" && "$percentage" -le "$threshold" ]]; then
      condition_met=true
    elif [[ "$normalized_state" == "charging" && "$percentage" -ge "$threshold" ]]; then
      condition_met=true
    fi

    # If condition is met and we haven't notified for this level yet
    if [[ "$condition_met" == true && ! -f "$lock_file" ]]; then
      echo "Threshold met: $normalized_state at $percentage% (rule: $threshold%)"

      # Get the command(s) for this threshold
      declare -a commands
      readarray -t commands < <(yq -r ".$normalized_state.\"$threshold\"[]" "$CONFIG_FILE")

      # Execute all commands
      for cmd in "${commands[@]}"; do
        echo "Executing: $cmd"
        # Execute the command in a subshell to avoid script exit on error
        (eval "$cmd") &
      done

      # Create the lock file to prevent spamming
      touch "$lock_file"
    fi
  done
}

# Script Entrypoint
echo "🚀 Batty started. Monitoring for events..."

# Run once on startup
process_state

# Monitor for changes from UPower and re-process the state each time
upower --monitor | while read -r _; do
  process_state
done
