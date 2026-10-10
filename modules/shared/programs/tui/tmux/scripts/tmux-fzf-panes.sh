#!/usr/bin/env bash

set -euo pipefail

# 1. Function to list panes with current selection indicator
get_panes() {
  local curr
  curr="$(tmux display-message -p '#{pane_id}')"
  tmux list-panes -F "#{?#{==:#{pane_id},${curr}},*, }|Pane #{pane_index}|#{pane_current_command}|#{pane_current_path}|#{pane_id}" |
    column -t -s '|'
}

# Kill pane $1 (at 0-based fzf index $2), then write the 1-based position of
# the next non-current pane (wrapping) to $3 so fzf can focus it on reload
kill_and_pick_next() {
  local id="$1" idx="$2" posfile="$3" list total i line pick=""
  tmux kill-pane -t "$id" || true
  list="$(get_panes)"
  total="$(echo "$list" | grep -c . || true)"
  for ((i = 0; i < total; i++)); do
    line="$(echo "$list" | sed -n "$(((idx + i) % total + 1))p")"
    if [[ "$line" != '*'* ]]; then
      pick=$(((idx + i) % total + 1))
      break
    fi
  done
  echo "${pick:-$((idx < total ? idx + 1 : total))}" >"$posfile"
}

export -f get_panes kill_and_pick_next

# 2. Extract active item index
list="$(get_panes)"
pos="$(echo "$list" | grep -n '^\*' | cut -d: -f1 || echo 1)"
posfile="$(mktemp)"
trap 'rm -f "$posfile"' EXIT
echo "${pos:-1}" >"$posfile"
export posfile

# 3. Interactive fzf popup
target="$(echo "$list" | fzf \
  --prompt='  Pane: ' \
  --header='[Ctrl-X] Kill pane | [Enter] Select' \
  --bind "load:transform:echo pos(\$(cat \"\$posfile\"))" \
  --bind "ctrl-x:execute-silent(bash -c 'kill_and_pick_next \"\$@\"' _ {-1} {n} \"\$posfile\")+reload(bash -c get_panes)" \
  --preview 'id=$(echo {} | awk "{print \$NF}"); tmux capture-pane -p -e -t "$id"' \
  --preview-window=bottom,50%,nowrap,border-top |
  awk '{print $NF}')"

# 4. Switch to target pane
if [[ -n "${target:-}" ]]; then
  tmux select-pane -t "$target"
fi
