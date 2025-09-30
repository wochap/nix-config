#!/usr/bin/env bash

# TODO: find reason why audio consuming a lot of energy

if [ "$#" -ne 1 ]; then
  echo "Error: Incorrect number of arguments."
  echo "Usage: $0 [--listen|--performance|--balanced|--battery]"
  exit 1
fi

CHOICES_BACKUP_FILE="/tmp/shell_powerprofile_choices"
THEME_BACKUP_FILE="/tmp/shell_powerprofile_theme"
HYPR_BACKUP_FILE="/tmp/shell_powerprofile_hyprland_settings"
HYPRLAND_SETTINGS_TO_SAVE=(
  "animations:enabled"
  "decoration:shadow:enabled"
  "decoration:blur:enabled"
  "decoration:rounding"
)

save_hyprland_settings() {
  echo "Saving current Hyprland settings..."
  # Clear previous backup file
  >"$HYPR_BACKUP_FILE"

  for setting in "${HYPRLAND_SETTINGS_TO_SAVE[@]}"; do
    # Get the integer value of the setting and append it to the backup file
    hyprctl getoption "$setting" -j | jq '.int' >>"$HYPR_BACKUP_FILE"
  done

  echo "Settings saved to $HYPR_BACKUP_FILE"
}

restore_hyprland_settings() {
  if [ ! -f "$HYPR_BACKUP_FILE" ]; then
    echo "No backup file found. Nothing to restore."
    return
  fi

  echo "Restoring Hyprland settings..."

  # Read the saved values line by line
  mapfile -t values <"$HYPR_BACKUP_FILE"

  local batch_command=""
  for i in "${!HYPRLAND_SETTINGS_TO_SAVE[@]}"; do
    batch_command+="keyword ${HYPRLAND_SETTINGS_TO_SAVE[$i]} ${values[$i]};"
  done
  hyprctl --batch "$batch_command" &>/dev/null

  rm "$HYPR_BACKUP_FILE"
  echo "Settings restored and backup file removed."
}

listen() {
  local profile=$(powerprofilesctl get)
  echo "$profile"
  dbus-monitor --system "type='signal',interface='org.freedesktop.DBus.Properties',path='/net/hadess/PowerProfiles',member='PropertiesChanged',arg0='net.hadess.PowerProfiles'" 2>/dev/null |
    while read -r line; do
      # The line check is a simple way to make sure we react to the right signal block.
      # The output of dbus-monitor includes the property name "ActiveProfile".
      if [[ "$line" == *"ActiveProfile"* ]]; then
        local new_profile=$(powerprofilesctl get)
        echo "$new_profile"
      fi
    done
}

battery_saver() {
  echo "Switching to Battery-Saver Mode..."

  local PROFILE="$1"
  local options=("powerprofile" "systemd" "theme" "wifi" "bluetooth" "mic" "hyprland")
  local selected_options
  selected_options=$(
    IFS=,
    echo "${options[*]}"
  )
  local header="Please select components to disable for battery saving:"
  gum choose "${options[@]}" --no-limit --selected "$selected_options" --height 6 --header "$header" >"$CHOICES_BACKUP_FILE"

  if [ ! -s "$CHOICES_BACKUP_FILE" ]; then
    rm -f "$CHOICES_BACKUP_FILE"
    exit 0
  fi

  while IFS= read -r choice; do
    case "$choice" in
    powerprofile)
      powerprofilesctl set "$PROFILE"
      ;;
    hyprland)
      save_hyprland_settings
      hyprctl --batch "\
            keyword animations:enabled 0;\
            keyword decoration:shadow:enabled 0;\
            keyword decoration:blur:enabled 0;\
            keyword decoration:rounding 0;" &>/dev/null
      ;;
    systemd)
      echo "Stopping systemd services..."
      systemctl stop docker.service &>/dev/null
      ;;
    theme)
      echo "Saving current theme"
      local current_scheme=$(color-scheme print)
      echo "$current_scheme" >"$THEME_BACKUP_FILE"
      if [[ "$current_scheme" != "dark" ]]; then
        echo "Switching to dark..."
        theme-switch dark
      fi
      ;;
    wifi)
      echo "Turning off Wi-Fi..."
      nmcli radio wifi off
      ;;
    bluetooth)
      echo "Turning off Bluetooth..."
      echo "power off" | bluetoothctl
      mv ~/.config/wireplumber/wireplumber.conf.d/51-disable-suspension.conf /tmp/51-disable-suspension.conf
      systemctl --user restart pipewire.service
      systemctl --user restart shell.service
      ;;
    mic)
      pactl set-source-mute @DEFAULT_SOURCE@ true
      ;;
    esac
  done <"$CHOICES_BACKUP_FILE"

  echo "Battery-Saver Mode activated for selected components."
}

performance() {
  echo "Switching to Performance Mode..."

  if [ ! -f "$CHOICES_BACKUP_FILE" ]; then
    echo "No saved state from battery-saver mode found. No specific components to re-enable."
    powerprofilesctl set performance
  else
    echo "Restoring components based on saved state..."
    while IFS= read -r choice; do
      case "$choice" in
      powerprofile)
        powerprofilesctl set performance
        ;;
      hyprland)
        restore_hyprland_settings
        ;;
      systemd)
        echo "Starting services..."
        systemctl start docker.service
        ;;
      theme)
        if [ -f "$THEME_BACKUP_FILE" ]; then
          local saved_theme
          saved_theme=$(<"$THEME_BACKUP_FILE")
          local current_scheme=$(color-scheme print)
          if [[ "$current_scheme" != "$saved_theme" ]]; then
            echo "Restoring theme to '$saved_theme'..."
            theme-switch "$saved_theme"
          fi
          rm "$THEME_BACKUP_FILE"
        else
          echo "No saved theme found to restore."
        fi
        ;;
      wifi)
        echo "Turning on Wi-Fi..."
        nmcli radio wifi on
        ;;
      bluetooth)
        echo "Turning on Bluetooth..."
        echo "power on" | bluetoothctl
        mv /tmp/51-disable-suspension.conf ~/.config/wireplumber/wireplumber.conf.d/51-disable-suspension.conf
        systemctl --user restart pipewire.service
        systemctl --user restart shell.service
        ;;
      mic)
        pactl set-source-mute @DEFAULT_SOURCE@ false
        ;;
      esac
    done <"$CHOICES_BACKUP_FILE"

    rm "$CHOICES_BACKUP_FILE"

    echo "Component state restored."
  fi

  echo "Performance Mode activated."
}

case "$1" in
--listen)
  listen
  ;;
--battery)
  battery_saver "power-saver"
  ;;
--balanced)
  battery_saver "balanced"
  ;;
--performance)
  performance
  ;;
*)
  echo "Error: Invalid argument '$MODE'."
  echo "Usage: $0 [--listen|--performance|--balanced|--battery]"
  exit 1
  ;;
esac

exit 0
