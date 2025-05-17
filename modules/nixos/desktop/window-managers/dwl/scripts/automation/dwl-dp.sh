#!/usr/bin/env bash

# Kill previous tmux session
if tmux has-session -t dp 2>/dev/null; then
  echo "Killing tmux session: dp"
  tmux kill-session -t dp
fi
if tmux has-session -t dp-editors 2>/dev/null; then
  echo "Killing tmux session: dp-editors"
  tmux kill-session -t dp-editors
fi

# Focus DWL tag 2
# 125 = logo
# 3 = 2
ydotool key 125:1 3:1 3:0 125:0

echo "Starting tmux session: dp"
footclient --app-id=footclient-dp tmux new-session zsh -i -c "tmuxinator start dp" &
echo "Starting tmux session: dp-editors"
footclient --app-id=footclient-dp-editors tmux new-session zsh -i -c "tmuxinator start dp-editors" &
