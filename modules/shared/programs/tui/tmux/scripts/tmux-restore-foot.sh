#!/usr/bin/env bash

# Open every named tmux session (skips numbered ones and tmux-server) in its
# own footclient
#
# Usage: tmux-restore-foot [--restore]
#   --restore  first restore the last tmux-resurrect save (same as prefix + R),
#              otherwise only the sessions that are already running are opened

set -euo pipefail

restore=0
for arg in "$@"; do
  case "$arg" in
  --restore) restore=1 ;;
  -h | --help)
    sed -n '3,9p' "$0" | sed 's/^# \{0,1\}//'
    exit 0
    ;;
  *)
    echo "Unknown option: $arg (try --help)" >&2
    exit 1
    ;;
  esac
done

restore_script="$HOME/.config/tmux/plugins/resurrect/scripts/restore.sh"

# tmux-resurrect needs a running server to restore into
service="tmux-server.service"
if systemctl --user cat "$service" &>/dev/null; then
  # enableSystemd: the server is owned by the systemd user service
  if ! systemctl --user is-active --quiet "$service"; then
    if ! systemctl --user start "$service"; then
      echo "Failed to start $service, see: journalctl --user -u $service" >&2
      exit 1
    fi
  fi
elif ! tmux has-session 2>/dev/null; then
  tmux new-session -d -s tmux-server
fi

if ((restore)); then
  resurrect_dir="$(tmux show-option -gqv @resurrect-dir)"
  resurrect_dir="${resurrect_dir:-$HOME/.tmux/resurrect}"
  resurrect_dir="$(echo "$resurrect_dir" | sed "s,\$HOME,$HOME,g; s,\$HOSTNAME,$(hostname),g; s,\~,$HOME,g")"
  last_file="$resurrect_dir/last"

  if [[ ! -e "$last_file" ]]; then
    echo "No tmux-resurrect save found at $last_file" >&2
    exit 1
  fi

  # run-shell without -b blocks until the restore finishes
  tmux run-shell "$restore_script"

  # Session names from the save file, in saved order
  mapfile -t sessions < <(awk -F'\t' '$1 == "pane" && !seen[$2]++ { print $2 }' "$last_file")
else
  mapfile -t sessions < <(tmux list-sessions -F '#{session_name}')
fi

for session in "${sessions[@]}"; do
  [[ "$session" =~ ^[0-9]+$ || "$session" == "tmux-server" ]] && continue
  tmux has-session -t "=$session" 2>/dev/null || continue
  # Skip sessions already shown in a terminal
  [[ "$(tmux display-message -p -t "=$session:" '#{session_attached}')" != "0" ]] && continue
  footclient --no-wait -- tmux attach-session -t "=$session"
done
