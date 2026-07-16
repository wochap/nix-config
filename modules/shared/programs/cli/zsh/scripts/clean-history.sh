#!/usr/bin/env bash

# clean-history.sh — Clean zsh extended-history entries.
#
# Dependencies:
#   - gum     (interactive confirmation prompt)
#
# Creates a backup of the history file (overwriting any previous backup),
# then removes entries that are:
#   • longer than N characters  (default: 100)
#   • older  than X days        (default: 30)
# It also strips trailing blank lines from all kept entries.
#
# Usage:
#   clean-history.sh [--max-length N] [--max-age X] [--history-file PATH]

set -euo pipefail

# --- Defaults ---
MAX_CHARS=1000
MAX_DAYS=365
HISTORY_FILE="${HISTFILE:-$HOME/.config/zsh/.zsh_history}"

# --- Parse arguments ---
usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Options:
  -n, --max-length  N     Remove entries whose command exceeds N characters  (default: $MAX_CHARS)
  -x, --max-age    X      Remove entries older than X days                   (default: $MAX_DAYS)
  -f, --history-file PATH Path to the zsh history file                       (default: \$HISTFILE or ~/.zsh_history)
  -h, --help               Show this help message
EOF
  exit 0
}

while [[ $# -gt 0 ]]; do
  case $1 in
    -n|--max-length)
      MAX_CHARS="$2"; shift 2 ;;
    -x|--max-age)
      MAX_DAYS="$2"; shift 2 ;;
    -f|--history-file)
      HISTORY_FILE="$2"; shift 2 ;;
    -h|--help)
      usage ;;
    *)
      echo "Error: unknown option '$1'" >&2; exit 1 ;;
  esac
done

# --- Validate inputs ---
if [[ ! "$MAX_CHARS" =~ ^[0-9]+$ ]] || (( MAX_CHARS == 0 )); then
  echo "Error: --max-length must be a positive integer." >&2
  exit 1
fi
if [[ ! "$MAX_DAYS" =~ ^[0-9]+$ ]] || (( MAX_DAYS == 0 )); then
  echo "Error: --max-age must be a positive integer." >&2
  exit 1
fi
if [[ ! -f "$HISTORY_FILE" ]]; then
  echo "Error: history file not found at $HISTORY_FILE" >&2
  exit 1
fi

# --- Check dependencies ---
if ! command -v gum &>/dev/null; then
  echo "Error: 'gum' is required but not installed." >&2
  echo "       Install it: https://github.com/charmbracelet/gum#installation" >&2
  exit 1
fi

# --- Calculate cutoff timestamp ---
# Try GNU date first, then BSD/macOS date.
if ! cutoff_ts=$(date -d "$MAX_DAYS days ago" +%s 2>/dev/null); then
  if ! cutoff_ts=$(date -v-"${MAX_DAYS}"d +%s 2>/dev/null); then
    echo "Error: could not compute cutoff date. Unsupported 'date' command." >&2
    exit 1
  fi
fi

# --- Pre-flight summary ---
original_count=$(grep -c '^: [0-9]' "$HISTORY_FILE" || true)
file_size=$(du -h "$HISTORY_FILE" | cut -f1)

gum style \
  --border rounded \
  --border-foreground 212 \
  --padding "1 2" \
  --margin "1 0" \
  --bold \
  "🧹 ZSH History Cleaner" \
  "" \
  "  File:         $HISTORY_FILE ($file_size)" \
  "  Entries:      $original_count" \
  "  Max length:   $MAX_CHARS characters" \
  "  Max age:      $MAX_DAYS days" \
  "  Backup:       ${HISTORY_FILE}.bak"

if ! gum confirm "Proceed with cleaning?"; then
  echo "Aborted."
  exit 0
fi

# --- Create backup (overwrite any previous one) ---
BACKUP_FILE="${HISTORY_FILE}.bak"
cp -f "$HISTORY_FILE" "$BACKUP_FILE"
echo "Backup saved to $BACKUP_FILE"

# --- Filter history ---
# Zsh extended-history format:
#   : <timestamp>:<elapsed>;<command>
# Multi-line commands use a trailing backslash on every line except the last.
#
# Strategy:
#   1. Reassemble multi-line entries into single logical entries.
#   2. For each logical entry, check timestamp and command length.
#   3. Strip trailing blank lines from kept entries.
#   4. Write kept entries back in the original multi-line format.

temp_file=$(mktemp) || { echo "Error: failed to create temp file." >&2; exit 1; }
trap 'rm -f "$temp_file"' EXIT

LC_ALL=C awk -v cutoff="$cutoff_ts" -v maxlen="$MAX_CHARS" '
BEGIN { entry = "" }

# Accumulate lines that belong to the same logical entry.
# A line ending with a backslash is a continuation.
{
  if (entry == "") {
    entry = $0
  } else {
    entry = entry "\n" $0
  }

  # If the line does NOT end with "\", the entry is complete.
  if (!/\\$/) {
    process_entry(entry)
    entry = ""
  }
}

END {
  # Flush any trailing entry (file ended mid-continuation).
  if (entry != "") process_entry(entry)
}

function process_entry(e,    first_line, ts, cmd, semi_pos, cleaned) {
  # Strip trailing blank continuation lines.  We MUST remove the
  # backslash together with the newline — otherwise the entry ends
  # with a dangling "\" that zsh reads as a continuation marker,
  # merging it with the next entry.
  while (e ~ /\\\n[ \t]*$/) {
    sub(/\\\n[ \t]*$/, "", e)
  }
  # Also strip any remaining trailing blank lines (no backslash).
  while (e ~ /\n[ \t]*$/) {
    sub(/\n[ \t]*$/, "", e)
  }

  # Skip completely empty entries.
  if (e == "") return

  # Extract the first line to parse the header.
  first_line = e
  sub(/\n.*/, "", first_line)

  # Parse  ": <timestamp>:<elapsed>;<command>"
  #   field 1 = ":"
  #   field 2 = " <timestamp>"
  # The command starts after the first semicolon.
  split(first_line, hdr, ":")
  ts = hdr[2]
  sub(/^ /, "", ts)

  # Skip entries with invalid/missing timestamps.
  if (ts !~ /^[0-9]+$/) return
  # Skip entries older than the cutoff.
  if (ts + 0 < cutoff + 0) return

  # Extract the command portion (everything after the first ";").
  semi_pos = index(e, ";")
  if (semi_pos == 0) return
  cmd = substr(e, semi_pos + 1)

  # Remove continuation backslashes + newlines for length measurement.
  gsub(/\\\n/, "", cmd)

  # Skip entries whose command exceeds maxlen.
  if (length(cmd) > maxlen) return

  # Entry passed all filters — keep it.
  print e
}
' "$HISTORY_FILE" > "$temp_file"

# --- Report & apply ---
kept_count=$(grep -c '^: [0-9]' "$temp_file" || true)
removed_count=$((original_count - kept_count))

mv -f "$temp_file" "$HISTORY_FILE"
trap - EXIT  # disarm cleanup since we moved the file

gum style \
  --border rounded \
  --border-foreground 76 \
  --padding "1 2" \
  --margin "1 0" \
  "✅ Cleaning complete" \
  "" \
  "  Removed: $removed_count entries" \
  "  Kept:    $kept_count entries"
