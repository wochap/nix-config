#!/usr/bin/env bash

# A single script to manage and monitor a command inhibition lock.
#
# This script combines a listener (using inotifywait) and a wrapper
# to create/remove a lock file, signaling when an inhibited process
# is running.

LOCK_DIR="/tmp"
LOCK_FILENAME="wlinhibit.lock"
LOCKFILE="$LOCK_DIR/$LOCK_FILENAME"

##
# Displays help and usage information.
##
usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTION | COMMAND]

A tool to manage and monitor a simple inhibition lock.

Options:
  --listen        👂 Listen for inhibit start/stop events and print them.
  --get-status    ❓ Check if the inhibition lock is currently active.
  --toggle        🔄 Toggle inhibition lock.
  -h, --help      📄 Display this help message.
EOF
}

##
# Listens for the creation and deletion of the lock file.
##
listen() {
  mkdir -p "$LOCK_DIR" # Ensure the directory exists

  get_status
  while true; do
    inotifywait -q -e create -e delete "$LOCK_DIR" |
      while read -r directory event filename; do
        if [[ "$filename" == "$LOCK_FILENAME" ]]; then
          get_status
        fi
      done
  done
}

##
# Checks if the lock file exists and reports the status.
##
get_status() {
  if [[ -f "$LOCKFILE" ]]; then
    printf -- 'true\n'
  else
    printf -- 'false\n'
  fi
}

##
# Manually creates or deletes the lock file.
##
toggle() {
  if [[ -f "$LOCKFILE" ]]; then
    pkill wlinhibit
  else
    touch "$LOCKFILE"
    (wlinhibit && rm -f "$LOCKFILE") &
  fi
}

# If no arguments are provided, show usage.
if [[ $# -eq 0 ]]; then
  usage
  exit 1
fi

# Parse the first argument to determine the mode of operation.
case "$1" in
--listen)
  listen
  ;;
--get-status)
  get_status
  ;;
--toggle)
  toggle
  ;;
-h | --help)
  usage
  ;;
*)
  usage
  ;;
esac

exit 0
