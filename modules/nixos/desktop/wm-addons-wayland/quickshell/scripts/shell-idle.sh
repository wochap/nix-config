#!/usr/bin/env bash

# A script to manage and monitor the idle state for hypridle.
#
# This script uses a lock file to signal whether idling should be inhibited.
# It can set the state, get the current state, or listen for state changes.

LOCK_DIR="/tmp"
LOCK_FILENAME="hypridle.lock"
LOCKFILE="$LOCK_DIR/$LOCK_FILENAME"

##
# Displays help and usage information.
##
usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTION]

A tool to manage and monitor idle status for hypridle.

Options:
  --set <on|off>      ✍️  Set the idle status.
                        'on' creates a lock file to inhibit idle.
                        'off' removes the lock file to allow idle.
  --status            ❓  Print the current status ('true' if inhibited, 'false' otherwise).
  --listen            👂  Listen for status changes and print them continuously.
  -h, --help          📄  Display this help message.
EOF
}

##
# Creates or removes the lock file to set the idle state.
# @param $1 - The desired state ('on' or 'off').
##
set_status() {
  case "$1" in
    on)
      touch "$LOCKFILE"
      ;;
    off)
      rm -f "$LOCKFILE"
      ;;
    *)
      echo "Error: Invalid argument for '--set'. Use 'on' or 'off'." >&2
      exit 1
      ;;
  esac
}

##
# Checks if the lock file exists and prints the status.
# 'true' means idle is inhibited.
# 'false' means idle is allowed.
##
print_status() {
  if [[ -f "$LOCKFILE" ]]; then
    printf -- 'true\n'
  else
    printf -- 'false\n'
  fi
}

##
# Listens for the creation and deletion of the lock file and prints the status.
##
listen() {
  # Ensure the directory exists so inotifywait can watch it.
  mkdir -p "$LOCK_DIR"

  # Print the initial status before starting the loop
  print_status

  # Watch the directory for file creation and deletion events
  while true; do
    inotifywait -q -e create -e delete "$LOCK_DIR" |
      while read -r directory event filename; do
        # If the event is for our specific lock file, print the new status
        if [[ "$filename" == "$LOCK_FILENAME" ]]; then
          print_status
        fi
      done
  done
}

# If no arguments are provided, show usage.
if [[ $# -eq 0 ]]; then
  usage
  exit 1
fi

# Parse the option.
case "$1" in
  --set)
    # Check if a second argument ('on' or 'off') was provided
    if [[ -z "$2" ]]; then
      echo "Error: '--set' option requires an argument ('on' or 'off')." >&2
      usage
      exit 1
    fi
    set_status "$2"
    ;;
  --status)
    print_status
    ;;
  --listen)
    listen
    ;;
  -h | --help)
    usage
    ;;
  *)
    echo "Error: Unknown option '$1'" >&2
    usage
    exit 1
    ;;
esac

exit 0
