#!/usr/bin/env bash

# Compute a compact title for a tmux window/tab (or the status-left path).
#
# usage: tmux-tab-name <mode> <path> <command> <pane_title> <window_name> \
#                      <auto_rename> <host> <num_windows>
#   mode: active   -> focused tab, generous budget (full title, capped)
#         inactive -> background tab, small budget that shrinks as tabs grow
#         left     -> status-left path, medium budget that shrinks as tabs grow
#
# Precedence:
#   - inactive tab: a custom title wins, trimmed to the budget. A custom title
#     is a meaningful pane_title (set via `select-pane -T` or an app OSC title),
#     or a window_name whose automatic-rename was turned off (i.e. set manually
#     via `rename-window` or by an app escape sequence).
#   - active tab / fallback: at a shell prompt the current path is shown (middle
#     dirs abbreviated to initials); inside a TUI/app the pane_title is used if
#     meaningful, else the command name.

set -u

mode="${1:-inactive}"
path="${2:-}"
command="${3:-}"
pane_title="${4:-}"
window_name="${5:-}"
auto_rename="${6:-on}"
host="${7:-}"
num_windows="${8:-1}"
[[ "$num_windows" =~ ^[0-9]+$ ]] || num_windows=1
command_base="${command##*/}"

ellipsis="…"
result=""

# Character budget per mode; inactive/left shrink as more windows are open.
case "$mode" in
  active) budget=50 ;;
  left)
    budget=$((40 - 2 * num_windows))
    ((budget < 16)) && budget=16
    ((budget > 32)) && budget=32
    ;;
  *)
    budget=$((30 - 2 * num_windows))
    ((budget < 8)) && budget=8
    ((budget > 22)) && budget=22
    ;;
esac

# Truncate $1 to $2 chars with a middle ellipsis. Sets result.
truncate_mid() {
  local s="$1" max="$2" len=${#1}
  if ((len <= max)); then
    result="$s"
    return
  fi
  if ((max <= 1)); then
    result="${s:0:1}"
    return
  fi
  local keep=$((max - 1)) head tail
  head=$(((keep + 1) / 2))
  tail=$((keep / 2))
  if ((tail > 0)); then
    result="${s:0:head}${ellipsis}${s: -tail}"
  else
    result="${s:0:head}${ellipsis}"
  fi
}

# Abbreviate a path to fit $2 chars. Sets result.
compact_path() {
  local p="$1" max="$2"
  case "$p" in
    "$HOME") p="~" ;;
    "$HOME"/*) p="~${p#"$HOME"}" ;;
  esac
  if (( ${#p} <= max )); then
    result="$p"
    return
  fi

  local -a parts
  IFS='/' read -r -a parts <<<"$p"
  local n=${#parts[@]}

  # No middle dirs to abbreviate (e.g. ~/foo or /foo): just truncate.
  if ((n <= 2)); then
    truncate_mid "$p" "$max"
    return
  fi

  # Abbreviate every middle component to its first char, keep root + basename.
  local out="${parts[0]}" i c
  for ((i = 1; i < n - 1; i++)); do
    c="${parts[i]}"
    [[ -z "$c" ]] && continue
    out+="/${c:0:1}"
  done
  out+="/${parts[n - 1]}"

  if (( ${#out} <= max )); then
    result="$out"
    return
  fi

  # Still too long: keep the abbreviated prefix, shrink the basename.
  local prefix="${out%/*}/" base="${out##*/}"
  if (( ${#prefix} >= max )); then
    truncate_mid "$out" "$max"
    return
  fi
  truncate_mid "$base" $((max - ${#prefix}))
  result="${prefix}${result}"
}

is_shell() {
  case "${1##*/}" in
    zsh | bash | fish | sh | ash | dash | -zsh | -bash | -fish | nix-shell) return 0 ;;
    *) return 1 ;;
  esac
}

# pane_title is "meaningful" when an app/user actually set it (not the default
# hostname or the bare command name).
pane_title_meaningful=0
if [[ -n "$pane_title" && "$pane_title" != "$host" && "$pane_title" != "$command" && "$pane_title" != "$command_base" ]]; then
  pane_title_meaningful=1
fi

# window_name is a genuine custom name only when automatic-rename was disabled
# for the window (tmux does this on `rename-window` or an app escape sequence);
# otherwise it just holds our own automatic-rename-format output.
window_custom=0
if [[ "$auto_rename" != "on" && -n "$window_name" && "$window_name" != "$host" && "$window_name" != "$command_base" ]]; then
  window_custom=1
fi

if [[ "$mode" == "inactive" ]]; then
  # Unfocused tab: a custom title (pane or window) takes precedence.
  if ((pane_title_meaningful)); then
    truncate_mid "$pane_title" "$budget"
  elif ((window_custom)); then
    truncate_mid "$window_name" "$budget"
  elif is_shell "$command"; then
    compact_path "$path" "$budget"
  else
    truncate_mid "$command_base" "$budget"
  fi
elif is_shell "$command"; then
  # Focused shell: show the current path.
  compact_path "$path" "$budget"
elif ((pane_title_meaningful)); then
  # Focused TUI/app: prefer the title the app set.
  truncate_mid "$pane_title" "$budget"
else
  truncate_mid "$command_base" "$budget"
fi

printf '%s' "$result"
