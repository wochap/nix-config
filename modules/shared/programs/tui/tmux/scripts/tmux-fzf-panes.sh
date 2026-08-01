#!/usr/bin/env bash

set -euo pipefail

# 1. Function to list panes with current selection indicator
get_panes() {
  local curr
  curr="$(tmux display-message -p '#{pane_id}')"
  tmux list-panes -F "#{?#{==:#{pane_id},${curr}},*, }|Pane #{pane_index}|#{pane_current_command}|#{pane_current_path}|#{pane_id}" |
    column -t -s '|'
}

export -f get_panes

# 2. Extract active item index
list="$(get_panes)"
pos="$(echo "$list" | grep -n '^\*' | cut -d: -f1 || echo 1)"

# 3. Interactive fzf popup
target="$(echo "$list" | fzf \
  --prompt='  Pane: ' \
  --header='[Ctrl-X] Kill pane | [Enter] Select' \
  --bind "load:pos(${pos:-1})" \
  --bind "ctrl-x:execute(id=\$(echo {} | awk '{print \$NF}'); tmux kill-pane -t \"\$id\")+reload(bash -c get_panes)" \
  --preview 'id=$(echo {} | awk "{print \$NF}"); tmux capture-pane -p -e -t "$id"' \
  --preview-window=bottom,50%,nowrap,border-top |
  awk '{print $NF}')"

# 4. Switch to target pane
if [[ -n "${target:-}" ]]; then
  tmux select-pane -t "$target"
fi
