#!/usr/bin/env bash

# Prints the last applied kanshi profile name from the journal
print_kanshi_profile() {
  journalctl -b 0 --user -u kanshi | grep "applying profile '" | tail -n 1 | cut -d "'" -f 2
}

# Returns "true" if the current kanshi profile name contains "power-saver"
print_is_kanshi_power_saver_profile_active() {
  print_kanshi_profile | grep -q "power-saver" && echo "true" || echo "false"
}

# Returns "true" if Hyprland's blur is enabled
print_is_hyprland_blur_enabled() {
  hyprctl getoption decoration.blur.enabled -j | jq -r '.bool'
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

print_iface_exists() {
  ip link show br-c700d6064c27 &>/dev/null && echo "true" || echo "false"
}

# Returns "true" if keyboard autosuspend is on
print_is_keyboard_autosuspend_on() {
  # Checks if the status is "on" (meaning power saving is active)
  [[ "$(legion-keyboard-autosuspend --status)" == "on" ]] && echo "true" || echo "false"
}

print_status() {
  # Returns "true" only if the system is already in power-saver mode.
  # This means the interface is down, blur is off, power-saver profile is active,
  # and keyboard autosuspend is on.
  if [[ "$(print_is_iface_up)" == "false" ]] &&
    [[ "$(print_is_hyprland_blur_enabled)" == "false" ]] &&
    [[ "$(print_is_kanshi_power_saver_profile_active)" == "true" ]] &&
    [[ "$(print_is_keyboard_autosuspend_on)" == "true" ]]; then
    echo "true"
  else
    echo "false"
  fi
}

enable() {
  echo "Activating power saver mode..."

  # Bring down the network interface
  if [[ "$(print_is_iface_up)" == "true" ]]; then
    echo " -> Bringing down network interface"
    pkexec ip link set br-c700d6064c27 down
  fi

  # Disable Hyprland blur
  if [[ "$(print_is_hyprland_blur_enabled)" == "true" ]]; then
    echo " -> Disabling hyprland blur"
    hyprctl eval 'hl.config({ decoration = { blur = { enabled = false } } })'
  fi

  # Activate kanshi power saver profile
  if [[ "$(print_is_kanshi_power_saver_profile_active)" == "false" ]]; then
    echo " -> Switching to kanshi power-saver profile"
    kanshictl switch glegion-undocked-power-saver
  fi

  # Enable keyboard autosuspend
  if [[ "$(print_is_keyboard_autosuspend_on)" == "false" ]]; then
    echo " -> Enabling keyboard autosuspend"
    legion-keyboard-autosuspend --toggle on
  fi
}

disable() {
  echo "Deactivating power saver mode..."

  # Bring up the network interface if it exists
  if [[ "$(print_iface_exists)" == "true" ]] && [[ "$(print_is_iface_up)" == "false" ]]; then
    echo " -> Bringing up network interface"
    pkexec ip link set br-c700d6064c27 up
  fi

  # Enable Hyprland blur
  if [[ "$(print_is_hyprland_blur_enabled)" == "false" ]]; then
    echo " -> Enabling hyprland blur"
    hyprctl eval 'hl.config({ decoration = { blur = { enabled = true } } })'
  fi

  # Activate standard kanshi profile
  if [[ "$(print_is_kanshi_power_saver_profile_active)" == "true" ]]; then
    echo " -> Switching to standard kanshi profile"
    kanshictl switch glegion-undocked
  fi

  # Disable keyboard autosuspend
  if [[ "$(print_is_keyboard_autosuspend_on)" == "true" ]]; then
    echo " -> Disabling keyboard autosuspend"
    legion-keyboard-autosuspend --toggle off
  fi
}

toggle() {
  # Do not use the aggregate status to choose a direction: one failed or delayed
  # component would otherwise make repeated toggles keep enabling power saver.
  # These two settings are explicit power-saver markers; if either is active,
  # reconcile every component to the disabled state.
  if [[ "$(print_is_kanshi_power_saver_profile_active)" == "true" ]] ||
    [[ "$(print_is_keyboard_autosuspend_on)" == "true" ]]; then
    disable
  else
    enable
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
--enable)
  enable
  ;;
--disable)
  disable
  ;;
--listen)
  listen
  ;;
--status | '')
  print_status
  ;;
*)
  echo "Usage: $0 [--toggle | --enable | --disable | --status]" >&2
  exit 1
  ;;
esac
