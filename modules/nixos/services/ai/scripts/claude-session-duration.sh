#!/usr/bin/env bash
#
# claude-session-duration.sh — show the time span of a Claude Code session:
# the date of the first user message, the date of the last assistant
# response, and the human-readable difference between them.
#
# Usage:
#   ./claude-session-duration.sh [session-file.jsonl | session-id]
#   ./claude-session-duration.sh            # uses the most recent session
#                                           # for the current project
#
# A session id (e.g. 452d352a-daac-4182-8099-0b391d4fe7ea) is looked up in
# the current project's sessions first, then across all Claude projects.
#
# Requires: jq

set -euo pipefail

if ! command -v jq >/dev/null 2>&1; then
  echo "Error: jq is required but not installed." >&2
  exit 1
fi

projects_root="$HOME/.claude/projects"
project_dir="$projects_root/$(pwd | sed 's|/|-|g')"

# Resolve the session file: a file path, a session id, or (with no
# argument) the newest session for the current project.
if [[ $# -ge 1 ]]; then
  if [[ -f "$1" ]]; then
    session_file="$1"
  else
    # Treat the argument as a session id (with or without .jsonl).
    session_id="${1%.jsonl}"
    if [[ -f "$project_dir/$session_id.jsonl" ]]; then
      session_file="$project_dir/$session_id.jsonl"
    else
      session_file=$(find "$projects_root" -maxdepth 2 -name "$session_id.jsonl" 2>/dev/null | head -1 || true)
      if [[ -z "$session_file" ]]; then
        echo "Error: no session file or session id matching '$1' found." >&2
        exit 1
      fi
    fi
  fi
else
  if [[ ! -d "$project_dir" ]]; then
    echo "Error: no Claude project directory found at $project_dir" >&2
    echo "Usage: $0 [session-file.jsonl | session-id]" >&2
    exit 1
  fi
  session_file=$(ls -t "$project_dir"/*.jsonl 2>/dev/null | head -1 || true)
  if [[ -z "$session_file" ]]; then
    echo "Error: no session files found in $project_dir" >&2
    exit 1
  fi
fi

if [[ ! -f "$session_file" ]]; then
  echo "Error: file not found: $session_file" >&2
  exit 1
fi

# Session name: latest ai-title entry, falling back to a summary entry.
session_name=$(jq -rs '
    ([ .[] | select(.type == "ai-title") | .aiTitle ] | last) //
    ([ .[] | select(.type == "summary") | .summary ] | last) //
    "(untitled)"' "$session_file")

# First user message timestamp (skip sidechain/subagent messages).
first_user=$(jq -rs '
    [ .[] | select(.type == "user" and (.isSidechain != true) and .timestamp) ]
    | first | .timestamp // empty' "$session_file")

# Last assistant response timestamp.
last_assistant=$(jq -rs '
    [ .[] | select(.type == "assistant" and (.isSidechain != true) and .timestamp) ]
    | last | .timestamp // empty' "$session_file")

if [[ -z "$first_user" ]]; then
  echo "Error: no user message found in $session_file" >&2
  exit 1
fi
if [[ -z "$last_assistant" ]]; then
  echo "Error: no assistant response found in $session_file" >&2
  exit 1
fi

first_epoch=$(date -d "$first_user" +%s)
last_epoch=$(date -d "$last_assistant" +%s)
diff_secs=$((last_epoch - first_epoch))

# Format duration as e.g. "2h 05m", "45m 12s", "3d 4h 10m".
format_duration() {
  local total=$1
  local days=$((total / 86400))
  local hours=$(((total % 86400) / 3600))
  local mins=$(((total % 3600) / 60))
  local secs=$((total % 60))
  local out=""
  ((days > 0)) && out+="${days}d "
  ((days > 0 || hours > 0)) && out+="${hours}h "
  if ((days > 0 || hours > 0)); then
    out+="$(printf '%02dm' "$mins")"
  elif ((mins > 0)); then
    out+="${mins}m $(printf '%02ds' "$secs")"
  else
    out+="${secs}s"
  fi
  echo "$out"
}

echo "Session name:        $session_name"
echo "Session file:        $session_file"
echo "First user message:  $(date -d "$first_user" '+%Y-%m-%d %H:%M:%S %Z')"
echo "Last Claude reply:   $(date -d "$last_assistant" '+%Y-%m-%d %H:%M:%S %Z')"
echo "Duration:            $(format_duration "$diff_secs")"
