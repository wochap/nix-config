#!/usr/bin/env bash

readonly logs_file_path="$HOME"/.cache/dwl/logs
timestamp=$(date +"%a-%d-%b-%H:%M-%Y")

if [[ -f "$logs_file_path" ]]; then
  mv "$logs_file_path" "${logs_file_path}_${timestamp}"
fi

# Redirect the output of journalctl to the log file
journalctl -f --user-unit=wayland-wm@dwl.service | while read -r line; do
  # Remove the timestamp and service name using sed
  clean_line=$(echo "$line" | sed 's/^[A-Za-z]\{3\} [0-9]\{2\} [0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\} [A-Za-z0-9_-]\+ [a-zA-Z0-9_-]\+\[[0-9]\+\]: //')

  # Append each cleaned line to the log file
  echo "$clean_line" >>"$logs_file_path"
done
