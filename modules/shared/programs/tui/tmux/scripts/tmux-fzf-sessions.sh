#!/usr/bin/env bash

set -euo pipefail

# 1. Function to list sessions with current selection indicator
get_sessions() {
  local curr
  curr="$(tmux display-message -p '#{session_id}')"
  awk -v curr="$curr" -F'|' '
    NR == FNR {
      panes[$1]++
      next
    }
    $2 == "tmux-server" { next }
    {
      sid = $1
      name = $2
      win = $3
      att = $4
      p = panes[sid] + 0
      star = (sid == curr) ? "*" : " "
      printf "%s|Session %s|(%s windows)|(%d panes)|%s|%s\n", star, name, win, p, att, sid
    }
  ' <(tmux list-panes -a -F '#{session_id}') <(tmux list-sessions -F '#{session_id}|#{session_name}|#{session_windows}|#{?session_attached,(attached),}') |
    column -t -s '|'
}

# Kill session $1 (at 0-based fzf index $2), then write the 1-based position of
# the next unattached session (wrapping) to $3 so fzf can focus it on reload
kill_and_pick_next() {
  local id="$1" idx="$2" posfile="$3" list total i line pick=""
  tmux kill-session -t "$id" || true
  list="$(get_sessions)"
  total="$(echo "$list" | grep -c . || true)"
  for ((i = 0; i < total; i++)); do
    line="$(echo "$list" | sed -n "$(((idx + i) % total + 1))p")"
    if [[ "$line" != *"(attached)"* ]]; then
      pick=$(((idx + i) % total + 1))
      break
    fi
  done
  echo "${pick:-$((idx < total ? idx + 1 : total))}" >"$posfile"
}

export -f get_sessions kill_and_pick_next

# 2. Extract active item index
list="$(get_sessions)"
pos="$(echo "$list" | grep -n '^\*' | cut -d: -f1 || echo 1)"
posfile="$(mktemp)"
trap 'rm -f "$posfile"' EXIT
echo "${pos:-1}" >"$posfile"
export posfile

# 3. Interactive fzf popup
target="$(echo "$list" | fzf \
  --prompt='  Session: ' \
  --header='[Ctrl-X] Delete session | [Enter] Switch' \
  --bind "load:transform:echo pos(\$(cat \"\$posfile\"))" \
  --bind "ctrl-x:execute-silent(bash -c 'kill_and_pick_next \"\$@\"' _ {-1} {n} \"\$posfile\")+reload(bash -c get_sessions)" \
  --preview 'id=$(echo {} | awk "{print \$NF}"); tmux capture-pane -p -e -t "$id:"' \
  --preview-window=bottom,50%,nowrap,border-top |
  awk '{print $NF}')"

# 4. Switch to target session
if [[ -n "${target:-}" ]]; then
  tmux switch-client -t "$target"
fi
