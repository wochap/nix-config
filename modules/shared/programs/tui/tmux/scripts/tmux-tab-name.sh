#!/usr/bin/env bash

# Compute a compact title for a tmux window/tab (or the status-left path).
#
# usage: tmux-tab-name <mode> <path> <command> <pane_title> <host> <num_windows>
#   mode: active   -> active tab, generous budget (full title, capped)
#         inactive -> background tab, small budget that shrinks as tabs grow
#         left     -> status-left path, medium budget that shrinks as tabs grow
#
# At a shell prompt the current path is shown (middle dirs abbreviated to
# initials). Inside a TUI/app the title the app set (pane_title) is preferred,
# falling back to the command name.

set -u

mode="${1:-inactive}"
path="${2:-}"
command="${3:-}"
pane_title="${4:-}"
host="${5:-}"
num_windows="${6:-1}"
[[ "$num_windows" =~ ^[0-9]+$ ]] || num_windows=1

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

if is_shell "$command"; then
  compact_path "$path" "$budget"
else
  # TUI/app: prefer the title the app set, else the command name.
  if [[ -n "$pane_title" && "$pane_title" != "$host" && "$pane_title" != "$command" ]]; then
    result="$pane_title"
  else
    result="${command##*/}"
  fi
  truncate_mid "$result" "$budget"
fi

printf '%s' "$result"
