#!/usr/bin/env bash

# Kill previous tmux session
if tmux has-session -t vtm 2>/dev/null; then
  echo "Killing tmux session: vtm"
  tmux kill-session -t vtm
fi
if tmux has-session -t vtm-editors 2>/dev/null; then
  echo "Killing tmux session: vtm-editors"
  tmux kill-session -t vtm-editors
fi

# Focus DWL tag 2
# 125 = logo
# 3 = 2
ydotool key 125:1 3:1 3:0 125:0

echo "Starting tmux session: vtm"
footclient --app-id=footclient-vtm tmux new-session zsh -i -c "tmuxinator start vtm" &
echo "Starting tmux session: vtm-editors"
footclient --app-id=footclient-vtm-editors tmux new-session zsh -i -c "tmuxinator start vtm-editors" &
