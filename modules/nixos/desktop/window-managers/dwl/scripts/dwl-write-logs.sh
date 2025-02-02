#!/usr/bin/env bash

readonly logs_file_path="$HOME"/.cache/dwl/logs
timestamp=$(date +"%a-%d-%b-%H:%M-%Y")

if [[ -f "$logs_file_path" ]]; then
  mv "$logs_file_path" "${logs_file_path}_${timestamp}"
fi

# Redirect the output of journalctl to the log file
journalctl --quiet --no-pager --follow --output=cat --no-tail --user-unit=wayland-wm@dwl.service | while read -r line; do
  # Append each cleaned line to the log file
  echo "$line" >>"$logs_file_path"
done
