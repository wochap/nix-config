#!/usr/bin/env bash

# Get list of tmux sessions
sessions=$(tmux list-sessions -F '#S')

# Loop through each session
for session in $sessions; do
  # Check if session name contains only numbers
  if [[ "$session" =~ ^[0-9]+$ ]]; then
    # Check if the session is attached
    if [[ -z $(tmux list-clients -t "$session" 2>/dev/null) ]]; then
      # Kill the session
      tmux kill-session -t "$session"
      if [[ "$1" != "--silent" ]]; then
        echo "Killed tmux session: $session"
      fi
    fi
  fi
done
