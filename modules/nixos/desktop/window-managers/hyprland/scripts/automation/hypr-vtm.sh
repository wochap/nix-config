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

# Focus workspace 2
hyprctl dispatch 'hl.dsp.focus({ workspace = 2, on_current_monitor = true })'

# Change to monocle layout
hyprctl eval 'hl.workspace_rule({ workspace = "2", layout = "monocle" })'

echo "Starting tmux session: vtm"
footclient --app-id=footclient-vtm tmux new-session zsh -i -c "tmuxinator start vtm" &
echo "Starting tmux session: vtm-editors"
footclient --app-id=footclient-vtm-editors tmux new-session zsh -i -c "tmuxinator start vtm-editors" &
