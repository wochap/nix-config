#!/usr/bin/env bash

# Get list of tmux sessions
sessions=$(tmux list-sessions | cut -d: -f1)

# Loop through each session
for session in $sessions; do
  # Check if session name contains only numbers
  if [[ "$session" =~ ^[0-9]+$ ]]; then
    # Delete the session
    tmux kill-session -t "$session"
    echo "Deleted session: $session"
  fi
done
