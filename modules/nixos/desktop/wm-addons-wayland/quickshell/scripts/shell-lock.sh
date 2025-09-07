#!/usr/bin/env bash

# Defines the usage instructions for the script.
usage() {
  echo "Usage: $0 [--listen | -h | --help]"
  echo
  echo "Monitors D-Bus for screen lock and unlock signals."
  echo
  echo "Options:"
  echo "  --listen      Listen for events and print 'true' for lock and 'false' for unlock."
  echo "  -h, --help    Display this help message and exit."
}

# Defines the main listener function.
listen() {
  # This command listens for signals from the logind Session interface on the system D-Bus.
  # Errors are redirected to /dev/null to hide irrelevant output.
  dbus-monitor --system "type='signal',interface='org.freedesktop.login1.Session'" 2>/dev/null |
    while read -r line; do
      # When a signal is received, we check if it's the Lock or Unlock signal.
      # The 'grep -o' extracts the specific signal name (the "member").
      signal=$(echo "$line" | grep -o "member=Lock\|member=Unlock")

      if [ "$signal" == "member=Lock" ]; then
        # The screen was locked.
        printf -- 'true\n'
      elif [ "$signal" == "member=Unlock" ]; then
        # The screen was unlocked.
        printf -- 'false\n'
      fi
    done
}

# If no arguments are provided, show usage.
if [ -z "$1" ]; then
  usage
  exit 1
fi

# Parse the command-line arguments.
case "$1" in
--listen)
  listen
  ;;
-h | --help)
  usage
  ;;
*)
  echo "Error: Invalid option '$1'"
  echo
  usage
  exit 1
  ;;
esac

exit 0
