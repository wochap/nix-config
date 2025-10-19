#!/usr/bin/env bash

# Prints the last applied kanshi profile name from the journal
print_kanshi_profile() {
  journalctl -b 0 --user -u kanshi | grep "applying profile '" | tail -n 1 | cut -d "'" -f 2
}

# Returns "true" if the current kanshi profile name contains "power-saver"
print_is_kanshi_power_saver_profile_active() {
  print_kanshi_profile | grep -q "power-saver" && echo "true" || echo "false"
}

# Returns "true" if Hyprland's blur is enabled (value is 1)
print_is_hyprland_blur_enabled() {
  [[ "$(hyprctl getoption decoration:blur:enabled -j | jq -r '.int')" -eq 1 ]] && echo "true" || echo "false"
}

# specific to my glegion profile
print_is_iface_up() {
  local iface="br-c700d6064c27"
  local output
  # Capture output and suppress stderr to handle non-existent interface
  output=$(ip -j link show "$iface" 2>/dev/null)

  if [[ -z "$output" ]]; then
    # Interface doesn't exist or command failed
    echo "false"
    return
  fi

  # Returns "true" if the interface's flags array contains "UP"
  echo "$output" | jq -r '.[0].flags | contains(["UP"])'
}

print_status() {
  # Returns "true" only if the system is already in power-saver mode.
  # This means the interface is down, blur is off, and the power-saver profile is active.
  if [[ "$(print_is_iface_up)" == "false" ]] &&
    [[ "$(print_is_hyprland_blur_enabled)" == "false" ]] &&
    [[ "$(print_is_kanshi_power_saver_profile_active)" == "true" ]]; then
    echo "true"
  else
    echo "false"
  fi
}

toggle() {
  # Toggles the system's power state.
  # If print_status is "false", it means we are NOT in power-saver mode, so we activate it.
  # If print_status is "true", it means we ARE in power-saver mode, so we deactivate it.
  if [[ "$(print_status)" == "false" ]]; then
    echo "Activating power saver mode..."

    # Bring down the network interface only if it's currently up
    if [[ "$(print_is_iface_up)" == "true" ]]; then
      echo " -> Bringing down network interface"
      pkexec ip link set br-c700d6064c27 down
    fi

    # Disable Hyprland blur only if it's currently enabled
    if [[ "$(print_is_hyprland_blur_enabled)" == "true" ]]; then
      echo " -> Disabling hyprland blur"
      hyprctl keyword decoration:blur:enabled 0
    fi

    # Activate kanshi power saver profile only if it's not already active
    if [[ "$(print_is_kanshi_power_saver_profile_active)" == "false" ]]; then
      echo " -> Switching to kanshi power-saver profile"
      kanshictl switch glegion-undocked-power-saver
    fi
  else
    echo "Deactivating power saver mode..."
    # Enable Hyprland blur only if it's currently disabled
    if [[ "$(print_is_hyprland_blur_enabled)" == "false" ]]; then
      echo " -> Enabling hyprland blur"
      hyprctl keyword decoration:blur:enabled 1
    fi

    # Activate standard kanshi profile only if the power saver is currently active
    if [[ "$(print_is_kanshi_power_saver_profile_active)" == "true" ]]; then
      echo " -> Switching to standard kanshi profile"
      kanshictl switch glegion-undocked
    fi
  fi
}

# listen() {
#   # Listens for kanshi profile changes and prints the new status
#   journalctl -f -b 0 --user -u kanshi | grep --line-buffered "applying profile '" | while read -r line; do
#     print_status
#   done
# }

case "$1" in
--toggle)
  toggle
  ;;
--listen)
  listen
  ;;
--status | '')
  print_status
  ;;
*)
  echo "Usage: $0 [--toggle | --status]" >&2
  exit 1
  ;;
esac
