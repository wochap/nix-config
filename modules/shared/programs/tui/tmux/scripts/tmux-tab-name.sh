#!/usr/bin/env bash

# Compute a compact title for a tmux window/tab (or the status-left path).
#
# usage: tmux-tab-name <mode> <path> <command> <pane_title> <window_name> \
#                      <auto_rename> <host> <num_windows> <client_width>
#   mode: active   -> focused tab, capped at 40 chars
#         inactive -> background tab, small budget that shrinks as tabs grow
#         left     -> status-left, always the cwd; budget is derived from the
#                     free space on the line (client width minus the centred
#                     window list), so it fills the bar when few tabs are open
#                     and trims down as tabs pile up
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
client_width="${9:-80}"
[[ "$client_width" =~ ^[0-9]+$ ]] || client_width=80
command_base="${command##*/}"

ellipsis="…"
result=""

# Base budgets: the active tab is capped; inactive tabs shrink as windows grow.
active_budget=40
inactive_budget=$((30 - 2 * num_windows))
((inactive_budget < 8)) && inactive_budget=8
((inactive_budget > 22)) && inactive_budget=22

# Character budget per mode.
case "$mode" in
active) budget=$active_budget ;;
inactive) budget=$inactive_budget ;;
left)
  # Space-aware: estimate the width of the centred window list, then take half
  # of what's left on the line. Tabs draw over the edges anyway, so this only
  # sets where trimming *starts* - tmux clips the rest. Few tabs + wide client
  # -> near-full path; many tabs -> trimmed down.
  tab_overhead=6 # index + icon + padding per tab
  windows_width=$((active_budget + tab_overhead + (num_windows - 1) * (inactive_budget + tab_overhead)))
  budget=$(((client_width - windows_width) / 2))
  ((budget < 16)) && budget=16
  ((budget > 80)) && budget=80
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
  if ((${#p} <= max)); then
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

  # Progressively abbreviate middle dirs, farthest from the basename first,
  # stopping as soon as the path fits. This keeps the informative near-basename
  # dirs full for as long as the budget allows instead of collapsing everything
  # to initials at once.
  local num_middle=$((n - 2)) abbrev out i c
  for ((abbrev = 1; abbrev <= num_middle; abbrev++)); do
    out="${parts[0]}"
    for ((i = 1; i < n - 1; i++)); do
      c="${parts[i]}"
      [[ -z "$c" ]] && continue
      if ((i <= abbrev)); then
        out+="/${c:0:1}"
      else
        out+="/$c"
      fi
    done
    out+="/${parts[n - 1]}"
    if ((${#out} <= max)); then
      result="$out"
      return
    fi
  done

  # Every middle dir abbreviated and still too long: keep the abbreviated
  # prefix, shrink the basename.
  local prefix="${out%/*}/" base="${out##*/}"
  if ((${#prefix} >= max)); then
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

if [[ "$mode" == "left" ]]; then
  # status-left always shows the current working directory.
  compact_path "$path" "$budget"
elif [[ "$mode" == "inactive" ]]; then
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
