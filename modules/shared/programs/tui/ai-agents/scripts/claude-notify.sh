#!/usr/bin/env bash
#
# claude-notify.sh — Claude Code desktop notification hook
#
# Reads the hook's JSON payload from stdin and sends a desktop notification.
# Title carries the session title (from the transcript), falling back to
# "Claude Code". Body carries the event description, pretty cwd, and —
# depending on event — the pending tool, the last assistant message, or
# the error type.
#
# Fires only for events that need your attention:
#   - Notification(permission_prompt) — Claude blocked on tool approval
#   - Notification(idle_prompt)       — Claude idle, waiting for input
#   - Notification(agent_needs_input) — background agent blocked on you
#   - Stop                            — turn finished
#   - StopFailure                     — turn ended due to API error
# PreToolUse is handled silently to record the last tool (enriches the
# permission_prompt body — the Notification fires before the pending
# tool_use is flushed to the transcript).
#
# Install:
#   chmod +x ~/.claude/hooks/claude-notify.sh
#
# Register in ~/.claude/settings.json:
#
# {
#   "hooks": {
#     "Notification": [
#       { "matcher": "permission_prompt", "hooks": [{ "type": "command", "command": "~/.claude/hooks/claude-notify.sh" }] },
#       { "matcher": "idle_prompt", "hooks": [{ "type": "command", "command": "~/.claude/hooks/claude-notify.sh", "async": true }] },
#       { "matcher": "agent_needs_input", "hooks": [{ "type": "command", "command": "~/.claude/hooks/claude-notify.sh", "async": true }] }
#     ],
#     "PreToolUse": [
#       { "matcher": "", "hooks": [{ "type": "command", "command": "~/.claude/hooks/claude-notify.sh", "async": true }] }
#     ],
#     "Stop": [
#       { "hooks": [{ "type": "command", "command": "~/.claude/hooks/claude-notify.sh", "async": true }] }
#     ],
#     "StopFailure": [
#       { "matcher": "", "hooks": [{ "type": "command", "command": "~/.claude/hooks/claude-notify.sh" }] }
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
STATE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/claude-notify"

# --- Helper: describe a tool call ---
describe_tool() {
  echo "$INPUT" | jq -r '
    if (.tool_input.description // "") != "" then "\(.tool_name): \(.tool_input.description)"
    elif .tool_name == "Bash" then "Bash: \(.tool_input.command // "" | .[0:120])"
    else .tool_name
    end' 2>/dev/null || echo "unknown tool"
}

# ============================================================
# PreToolUse: record the tool Claude is about to run (silent)
# ============================================================
if [[ "$EVENT" == "PreToolUse" ]]; then
  mkdir -p "$STATE_DIR"
  describe_tool >"$STATE_DIR/last-tool-$SESSION_ID" 2>/dev/null || true
  exit 0
fi

# --- Common fields ---
CWD=$(echo "$INPUT" | jq -r '.cwd // ""')
TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // ""')
PRETTY_CWD="${CWD/#$HOME/\~}"

# Session title: last ai-title / custom-title entry in the transcript.
# Renaming a session appends a new title line, so the last one wins.
SESSION_NAME=""
if [[ -n "$TRANSCRIPT" && -r "$TRANSCRIPT" ]]; then
  SESSION_NAME=$(tac "$TRANSCRIPT" 2>/dev/null |
    grep -m1 -oE '"(aiTitle|customTitle)":"([^"\\]|\\.)*"' |
    head -1 | sed -E 's/^"(aiTitle|customTitle)":"//; s/"$//') || true
fi

# Last tool Claude attempted (from PreToolUse state file)
LAST_TOOL=""
if [[ -r "$STATE_DIR/last-tool-$SESSION_ID" ]]; then
  LAST_TOOL=$(<"$STATE_DIR/last-tool-$SESSION_ID")
fi

TITLE="${SESSION_NAME:-Claude Code}"
BODY=""

case "$EVENT" in
Notification)
  TYPE=$(echo "$INPUT" | jq -r '.notification_type // "unknown"')
  case "$TYPE" in
  permission_prompt)
    BODY="Claude needs your permission<br>$PRETTY_CWD"
    [[ -n "$LAST_TOOL" ]] && BODY+="<br><i>$LAST_TOOL</i>"
    ;;
  agent_needs_input)
    BODY="Claude is waiting for your input<br>$PRETTY_CWD"
    [[ -n "$LAST_TOOL" ]] && BODY+="<br><i>$LAST_TOOL</i>"
    ;;
  idle_prompt)
    BODY="Ready for your next prompt<br>$PRETTY_CWD"
    ;;
  *)
    MESSAGE=$(echo "$INPUT" | jq -r '.message // "Claude Code notification"')
    BODY="$MESSAGE<br>$PRETTY_CWD"
    ;;
  esac
  ;;
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
  [[ -n "$LAST_MSG" ]] && BODY+="<br><i>$LAST_MSG</i>"
  ;;
StopFailure)
  ERROR_TYPE=$(echo "$INPUT" | jq -r '.error // "unknown"')
  BODY="Stopped due to an error ($ERROR_TYPE)<br>$PRETTY_CWD"
  ;;
*)
  # Settings only register the events above; this should never fire.
  exit 0
  ;;
esac

# --- Send the notification (auto-detects OS) ---
if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS
  osascript -e "display notification \"$BODY\" with title \"$TITLE\""

elif command -v notify-send >/dev/null 2>&1; then
  # Linux (requires libnotify)
  notify-send --app-name="claude-code" --app-icon="claude-code" --icon="claude-code" --hint=string:custom-sound:message "$TITLE" "$BODY"

elif command -v powershell.exe >/dev/null 2>&1; then
  # WSL / Windows
  powershell.exe -Command "[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms'); [System.Windows.Forms.MessageBox]::Show('$BODY', '$TITLE')"

else
  echo "No supported notification backend found (osascript/notify-send/powershell.exe)" >&2
fi

exit 0
