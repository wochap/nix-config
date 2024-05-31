#!/usr/bin/env bash

# Kill previous tmux session
if tmux has-session -t vtm 2>/dev/null; then
  echo "Killing previous tmux session: vtm"
  tmux kill-session -t se
fi

# Focus DWL tag 2
ydotool key 125:1 3:1 3:0 125:0

echo "Start new tmux session"
footclient tmux new-session zsh -i -c "tmuxinator start vtm" &
footclient tmux new-session zsh -i -c "tmuxinator start vtm-editors" &
