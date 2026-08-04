#!/usr/bin/env bash
#
# codex-notify.sh — Codex CLI desktop notification hook
#
# Reads the hook's JSON payload from stdin and sends a desktop notification.
# Title carries the session name (from ~/.codex/session_index.jsonl), falling
# back to "Codex". Body carries the event description, pretty cwd, and —
# depending on event — the pending tool or the last agent message.
#
# Fires only for events that need your attention:
#   - Stop             — turn finished, Codex is idle waiting for you
#   - PermissionRequest — Codex blocked on tool approval (runs in the
#                         approval path; this hook only observes and never
#                         prints a decision, so the normal prompt continues)
#   - SessionEnd       — session exited
#
# IMPORTANT: Codex parses hook stdout as a decision. This script must never
# print to stdout, and must always exit 0, so it can never accidentally
# allow/deny a permission request or block a turn.
#
# Install:
#   chmod +x ~/.codex/hooks/codex-notify.sh
#
# Register in ~/.codex/hooks.json (requires trust via `/hooks` in the TUI,
# or a pre-seeded trusted_hash under [hooks.state] in config.toml):
#
# {
#   "hooks": {
#     "Stop": [
#       { "hooks": [{ "type": "command", "command": "~/.codex/hooks/codex-notify.sh" }] }
#     ],
#     "PermissionRequest": [
#       { "hooks": [{ "type": "command", "command": "~/.codex/hooks/codex-notify.sh" }] }
#     ],
#     "SessionEnd": [
#       { "hooks": [{ "type": "command", "command": "~/.codex/hooks/codex-notify.sh", "timeout": 3 }] }
#     ]
#   }
# }

set -Eeuo pipefail

# Contract: this hook is observe-only — it must never print to stdout and
# must always exit 0, so it can never block a turn or be parsed as a
# permission decision. If anything below goes wrong, exit cleanly instead of
# surfacing a hook error.
trap 'exit 0' ERR
# Ignore SIGPIPE so an early-exiting reader becomes a write error (handled by
# the ERR trap above) instead of killing the script with exit code 141.
trap '' PIPE

INPUT=$(cat)

EVENT=$(echo "$INPUT" | jq -r '.hook_event_name // ""')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
CODEX_HOME_DIR="${CODEX_HOME:-$HOME/.codex}"

# --- Helper: describe the tool Codex wants to run ---
# Codex hands us the real tool_input, so prefer a native description when the
# agent provided one; otherwise summarize the command/args.
describe_tool() {
  echo "$INPUT" | jq -r '
    def trunc($n): tostring | if length > $n then .[0:$n] + "…" else . end;
    if ((.tool_input.description // "") | type) == "string" and (.tool_input.description // "") != "" then
      "\(.tool_name): \(.tool_input.description | trunc(120))"
    elif .tool_name == "Bash" then "shell: \(.tool_input.command // "" | trunc(100))"
    elif .tool_name == "apply_patch" then "apply_patch: \(.tool_input | tojson | trunc(50))"
    else "\(.tool_name): \(.tool_input | tojson | trunc(50))"
    end' 2>/dev/null || echo "unknown tool"
}

# --- Common fields ---
CWD=$(echo "$INPUT" | jq -r '.cwd // ""')
MODEL=$(echo "$INPUT" | jq -r '.model // ""')
PRETTY_CWD="${CWD/#$HOME/\~}"

# Session title: session_index.jsonl is append-only; the newest entry for
# this session id wins (renaming a session appends a new line).
SESSION_NAME=""
SESSION_INDEX="$CODEX_HOME_DIR/session_index.jsonl"
if [[ "$SESSION_ID" != "unknown" && -r "$SESSION_INDEX" ]]; then
  SESSION_NAME=$(jq -rs --arg id "$SESSION_ID" '
    map(select((.id // "") == $id)) | last | .thread_name // empty
  ' "$SESSION_INDEX" 2>/dev/null) || true
fi

TITLE="${SESSION_NAME:-Codex}"
BODY=""
URGENCY="normal"

case "$EVENT" in
Stop)
  # stop_hook_active=true means a Stop hook already re-triggered this turn;
  # skip to avoid a duplicate ping on the loop.
  STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')
  [[ "$STOP_HOOK_ACTIVE" == "true" ]] && exit 0
  # Truncate inside jq: piping into `head -c 80` makes head close the pipe
  # early, so jq dies of SIGPIPE (hook exit 141) whenever the message is
  # longer than 80 bytes.
  LAST_MSG=$(echo "$INPUT" | jq -r '
    def trunc($n): tostring | if length > $n then .[0:$n] + "…" else . end;
    (.last_assistant_message // "") | trunc(80)')
  BODY="Finished<br>$PRETTY_CWD"
  [[ -n "$MODEL" ]] && BODY+=" ($MODEL)"
  [[ -n "$LAST_MSG" ]] && BODY+="<br><i>$LAST_MSG</i>"
  ;;
PermissionRequest)
  TOOL_DESC=$(describe_tool)
  BODY="Codex needs your permission<br>$PRETTY_CWD"
  [[ -n "$TOOL_DESC" ]] && BODY+="<br><i>$TOOL_DESC</i>"
  URGENCY="critical"
  ;;
SessionEnd)
  BODY="Session ended<br>$PRETTY_CWD"
  ;;
*)
  # hooks.json only registers the events above; this should never fire.
  exit 0
  ;;
esac

# --- Send the notification (auto-detects OS) ---
if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS
  osascript -e "display notification \"$BODY\" with title \"$TITLE\""

elif command -v notify-send >/dev/null 2>&1; then
  # Linux (requires libnotify)
  notify-send --app-name="codex" --app-icon="codex" --icon="codex" --urgency="$URGENCY" --hint=string:custom-sound:message "$TITLE" "$BODY"

elif command -v powershell.exe >/dev/null 2>&1; then
  # WSL / Windows
  powershell.exe -Command "[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms'); [System.Windows.Forms.MessageBox]::Show('$BODY', '$TITLE')"

else
  echo "No supported notification backend found (osascript/notify-send/powershell.exe)" >&2
fi

exit 0
