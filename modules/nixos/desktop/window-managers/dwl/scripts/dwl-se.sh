#!/usr/bin/env bash

# Kill previous tmux session
if tmux has-session -t se 2>/dev/null; then
  echo "Killing previous tmux session: se"
  tmux kill-session -t se
fi
if tmux has-session -t se-editors 2>/dev/null; then
  echo "Killing previous tmux session: se-editors"
  tmux kill-session -t se-editors
fi

# Focus DWL tag 2
ydotool key 125:1 3:1 3:0 125:0

# Start new foot terminal with tmux session
echo "Start new tmux session"
footclient tmux new-session zsh -i -c 'tmuxinator start se-editors' &
footclient tmux new-session zsh -i -c 'tmuxinator start se'
