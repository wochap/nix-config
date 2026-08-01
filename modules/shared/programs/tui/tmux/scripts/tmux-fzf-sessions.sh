#!/usr/bin/env bash

set -euo pipefail

# 1. Function to list sessions with current selection indicator
get_sessions() {
  local curr
  curr="$(tmux display-message -p '#{session_id}')"
  tmux list-sessions -F "#{?#{==:#{session_id},${curr}},*, }|Session #{session_name}|(#{session_windows} windows)|#{?session_attached,(attached),}|#{session_id}" |
    column -t -s '|'
}

export -f get_sessions

# 2. Extract active item index
list="$(get_sessions)"
pos="$(echo "$list" | grep -n '^\*' | cut -d: -f1 || echo 1)"

# 3. Interactive fzf popup
target="$(echo "$list" | fzf \
  --prompt='  Session: ' \
  --header='[Ctrl-X] Delete session | [Enter] Switch' \
  --bind "load:pos(${pos:-1})" \
  --bind "ctrl-x:execute(id=\$(echo {} | awk '{print \$NF}'); tmux kill-session -t \"\$id\")+reload(bash -c get_sessions)" \
  --preview 'id=$(echo {} | awk "{print \$NF}"); tmux capture-pane -p -e -t "$id:"' \
  --preview-window=bottom,50%,nowrap,border-top |
  awk '{print $NF}')"

# 4. Switch to target session
if [[ -n "${target:-}" ]]; then
  tmux switch-client -t "$target"
fi
