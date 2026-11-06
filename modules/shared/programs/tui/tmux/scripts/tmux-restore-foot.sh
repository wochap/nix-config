#!/usr/bin/env bash

# Save or restore tmux sessions, opening/moving each session in its own footclient
# and saving/restoring Hyprland workspaces when running inside Hyprland.
#
# Usage: tmux-restore-foot [OPTIONS]
#   --save             Save current tmux sessions (tmux-resurrect) and Hyprland workspaces
#   --restore          Restore tmux sessions (tmux-resurrect) and open/move footclients
#   -L <socket-name>   Specify tmux server socket name (default: "default")
#   -h, --help         Show this help message

set -euo pipefail

action="restore"
restore_resurrect=0
tmux_socket="default"

show_help() {
  sed -n '3,10p' "$0" | sed 's/^# \{0,1\}//'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
  --save)
    action="save"
    shift
    ;;
  --restore)
    action="restore"
    restore_resurrect=1
    shift
    ;;
  -L)
    if [[ $# -lt 2 ]]; then
      echo "Error: -L requires a socket name argument" >&2
      exit 1
    fi
    tmux_socket="$2"
    shift 2
    ;;
  -h | --help)
    show_help
    exit 0
    ;;
  *)
    echo "Unknown option: $1 (try --help)" >&2
    exit 1
    ;;
  esac
done

tmux_cmd() {
  tmux -L "$tmux_socket" "$@"
}

get_resurrect_dir() {
  local dir
  dir="$(tmux_cmd show-option -gqv @resurrect-dir 2>/dev/null || true)"
  dir="${dir:-$HOME/.tmux/resurrect}"
  dir="$(echo "$dir" | sed "s,\$HOME,$HOME,g; s,\$HOSTNAME,$(hostname),g; s,\~,$HOME,g")"
  echo "$dir"
}

is_hyprland() {
  [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] && command -v hyprctl &>/dev/null
}

move_hyprland_window() {
  local target_ws="$1"
  local win_selector="$2"
  # Using Hyprland Lua dispatcher syntax compatible with Hyprland 0.56+
  hyprctl dispatch "hl.dsp.window.move({ workspace = \"$target_ws\", follow = false, window = \"$win_selector\" })" &>/dev/null || true
}

# ---------------------------------------------------------
# SAVE ACTION
# ---------------------------------------------------------
if [[ "$action" == "save" ]]; then
  if ! tmux_cmd has-session 2>/dev/null; then
    echo "tmux-restore-foot: No running tmux session found for socket '$tmux_socket'." >&2
    exit 0
  fi

  # Trigger tmux-resurrect save
  # Look up resurrect save script path or fallback to default location
  save_script="$(tmux_cmd show-option -gqv @resurrect-save-script-path 2>/dev/null || true)"
  save_script="${save_script:-$HOME/.config/tmux/plugins/resurrect/scripts/save.sh}"

  if [[ -x "$save_script" ]]; then
    tmux_cmd run-shell "$save_script"
  else
    echo "tmux-restore-foot: resurrect save script not found at $save_script" >&2
  fi

  # If in Hyprland, record each session's foot window workspace
  if is_hyprland; then
    resurrect_dir="$(get_resurrect_dir)"
    mkdir -p "$resurrect_dir"
    ws_file="$resurrect_dir/hyprland_workspaces"

    # Query active clients in tmux: #{session_name} #{client_tty}
    mapfile -t client_lines < <(tmux_cmd list-clients -F '#{session_name} #{client_tty}' 2>/dev/null || true)

    # For each client, use OSC title probe to reliably identify which Hyprland window corresponds to which tmux session
    temp_ws_file="$(mktemp)"
    for line in "${client_lines[@]}"; do
      [[ -z "$line" ]] && continue
      sess="${line%% *}"
      tty="${line#* }"

      [[ "$sess" =~ ^[0-9]+$ || "$sess" == "tmux-server" ]] && continue
      [[ ! -w "$tty" ]] && continue

      probe_title="__tmux_ws_probe_${sess}_$$__"
      # Send OSC 0 to temporarily set the terminal window title
      printf '\033]0;%s\a' "$probe_title" > "$tty" || continue
      sleep 0.05

      ws="$(hyprctl clients -j 2>/dev/null | jq -r --arg t "$probe_title" '.[] | select(.title == $t) | .workspace.name' | head -n 1)"

      # Reset title to "foot"
      printf '\033]0;foot\a' > "$tty" || true

      if [[ -n "$ws" && "$ws" != "null" ]]; then
        echo -e "${sess}\t${ws}" >> "$temp_ws_file"
      fi
    done

    mv "$temp_ws_file" "$ws_file"
  fi

  exit 0
fi

# ---------------------------------------------------------
# RESTORE ACTION
# ---------------------------------------------------------
restore_script="$HOME/.config/tmux/plugins/resurrect/scripts/restore.sh"

# tmux-resurrect needs a running server to restore into
service="tmux-server.service"
if [[ "$tmux_socket" == "default" ]] && systemctl --user cat "$service" &>/dev/null; then
  # enableSystemd: the server is owned by the systemd user service
  if ! systemctl --user is-active --quiet "$service"; then
    if ! systemctl --user start "$service"; then
      echo "Failed to start $service, see: journalctl --user -u $service" >&2
      exit 1
    fi
  fi
elif ! tmux_cmd has-session 2>/dev/null; then
  tmux_cmd new-session -d -s tmux-server
fi

resurrect_dir="$(get_resurrect_dir)"
last_file="$resurrect_dir/last"
ws_file="$resurrect_dir/hyprland_workspaces"

declare -A session_workspaces=()
if is_hyprland && [[ -f "$ws_file" ]]; then
  while IFS=$'\t' read -r s_name s_ws; do
    [[ -n "$s_name" && -n "$s_ws" ]] && session_workspaces["$s_name"]="$s_ws"
  done < "$ws_file"
fi

if ((restore_resurrect)); then
  if [[ ! -e "$last_file" ]]; then
    echo "No tmux-resurrect save found at $last_file" >&2
    exit 1
  fi

  # run-shell without -b blocks until the restore finishes
  tmux_cmd run-shell "$restore_script"

  # Session names from the save file, in saved order
  mapfile -t sessions < <(awk -F'\t' '$1 == "pane" && !seen[$2]++ { print $2 }' "$last_file")
else
  mapfile -t sessions < <(tmux_cmd list-sessions -F '#{session_name}' 2>/dev/null || true)
fi

for session in "${sessions[@]}"; do
  [[ "$session" =~ ^[0-9]+$ || "$session" == "tmux-server" ]] && continue
  tmux_cmd has-session -t "=$session" 2>/dev/null || continue

  target_ws="${session_workspaces[$session]:-}"

  # If session is already attached to a terminal, just move that terminal window if needed
  attached="$(tmux_cmd display-message -p -t "=$session:" '#{session_attached}' 2>/dev/null || echo 0)"
  if [[ "$attached" != "0" ]]; then
    if is_hyprland && [[ -n "$target_ws" ]]; then
      client_tty="$(tmux_cmd display-message -p -t "=$session:" '#{client_tty}' 2>/dev/null || true)"
      if [[ -w "$client_tty" ]]; then
        probe_title="__tmux_ws_probe_${session}_$$__"
        printf '\033]0;%s\a' "$probe_title" > "$client_tty" || true
        sleep 0.05
        addr="$(hyprctl clients -j 2>/dev/null | jq -r --arg t "$probe_title" '.[] | select(.title == $t) | .address' | head -n 1)"
        printf '\033]0;foot\a' > "$client_tty" || true
        if [[ -n "$addr" && "$addr" != "null" ]]; then
          move_hyprland_window "$target_ws" "address:$addr"
        fi
      fi
    fi
    continue
  fi

  # Launch a new footclient for this session
  # If we have a target workspace in Hyprland, assign an initial-title so we can find & move it immediately
  if is_hyprland && [[ -n "$target_ws" ]]; then
    init_title="__foot_tmux_${session}_$$__"
    footclient --title="$init_title" --no-wait -- tmux -L "$tmux_socket" attach-session -t "=$session"

    # Move window to target workspace and reset title
    for _ in {1..20}; do
      sleep 0.05
      addr="$(hyprctl clients -j 2>/dev/null | jq -r --arg t "$init_title" '.[] | select(.initialTitle == $t or .title == $t) | .address' | head -n 1)"
      if [[ -n "$addr" && "$addr" != "null" ]]; then
        move_hyprland_window "$target_ws" "address:$addr"
        break
      fi
    done
  else
    footclient --no-wait -- tmux -L "$tmux_socket" attach-session -t "=$session"
  fi
done
