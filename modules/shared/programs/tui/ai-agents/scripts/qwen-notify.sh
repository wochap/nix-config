#!/usr/bin/env bash
#
# qwen-notify.sh — Qwen Code desktop notification hook
#
# Reads the hook's JSON payload from stdin and sends a desktop notification.
# Title carries the session title (from the transcript), falling back to
# "Qwen Code". Body carries the event description, pretty cwd, and —
# depending on event — the pending tool, context %, or error type.
#
# Fires only for events that need your attention:
#   - Notification(permission_prompt) — Qwen blocked on tool approval
#   - Notification(idle_prompt)       — Qwen idle, waiting for input
#   - Stop                            — turn finished
#   - StopFailure                     — turn ended due to API error
# PreToolUse is handled silently to record the last tool (enriches the
# permission_prompt body — the Notification fires before the pending
# tool_use is flushed to the transcript).
#
# Install:
#   chmod +x ~/.qwen/hooks/qwen-notify.sh
#
# Register in ~/.qwen/settings.json:
#
# {
#   "hooks": {
#     "Notification": [
#       { "matcher": "permission_prompt", "hooks": [{ "type": "command", "command": "~/.qwen/hooks/qwen-notify.sh" }] },
#       { "matcher": "idle_prompt", "hooks": [{ "type": "command", "command": "~/.qwen/hooks/qwen-notify.sh", "async": true }] }
#     ],
#     "PreToolUse": [
#       { "matcher": "", "hooks": [{ "type": "command", "command": "~/.qwen/hooks/qwen-notify.sh", "async": true }] }
#     ],
#     "Stop": [
#       { "hooks": [{ "type": "command", "command": "~/.qwen/hooks/qwen-notify.sh", "async": true }] }
#     ],
#     "StopFailure": [
#       { "matcher": "", "hooks": [{ "type": "command", "command": "~/.qwen/hooks/qwen-notify.sh" }] }
#     ]
#   }
# }

set -euo pipefail

INPUT=$(cat)

EVENT=$(echo "$INPUT" | jq -r '.hook_event_name // ""')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
STATE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/qwen-notify"

# --- Helper: describe a tool call ---
describe_tool() {
  echo "$INPUT" | jq -r '
    if (.tool_input.description // "") != "" then "\(.tool_name): \(.tool_input.description)"
    elif .tool_name == "run_shell_command" then "shell: \(.tool_input.command // "" | .[0:120])"
    elif .tool_name == "edit" then "edit: \(.tool_input.file_path // "" | split("/") | last)"
    elif .tool_name == "write_file" then "write: \(.tool_input.file_path // "" | split("/") | last)"
    elif .tool_name == "read_file" then "read: \(.tool_input.file_path // "" | split("/") | last)"
    elif .tool_name == "grep_search" then "grep: \(.tool_input.pattern // "")"
    elif .tool_name == "glob" then "glob: \(.tool_input.pattern // "")"
    elif .tool_name == "agent" then "agent: \(.tool_input.description // "")"
    else .tool_name
    end' 2>/dev/null || echo "unknown tool"
}

# ============================================================
# PreToolUse: record the tool Qwen is about to run (silent)
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

# Session title: last custom_title system record in the transcript JSONL.
# Renaming a session appends a new record, so the last one wins.
SESSION_NAME=""
if [[ -n "$TRANSCRIPT" && -r "$TRANSCRIPT" ]]; then
  SESSION_NAME=$(tac "$TRANSCRIPT" 2>/dev/null |
    grep -m1 '"subtype":"custom_title"' |
    jq -r '.systemPayload.customTitle // empty' 2>/dev/null) || true
fi

# Last tool Qwen attempted (from PreToolUse state file)
LAST_TOOL=""
if [[ -r "$STATE_DIR/last-tool-$SESSION_ID" ]]; then
  LAST_TOOL=$(<"$STATE_DIR/last-tool-$SESSION_ID")
fi

TITLE="${SESSION_NAME:-Qwen Code}"
BODY=""

case "$EVENT" in
Notification)
  TYPE=$(echo "$INPUT" | jq -r '.notification_type // "unknown"')
  case "$TYPE" in
  permission_prompt)
    BODY="Qwen needs your permission<br>$PRETTY_CWD"
    [[ -n "$LAST_TOOL" ]] && BODY+="<br>$LAST_TOOL"
    ;;
  idle_prompt)
    BODY="Ready for your next prompt<br>$PRETTY_CWD"
    ;;
  *)
    MESSAGE=$(echo "$INPUT" | jq -r '.message // "Qwen Code notification"')
    BODY="$MESSAGE<br>$PRETTY_CWD"
    ;;
  esac
  ;;
Stop)
  CONTEXT_USAGE=$(echo "$INPUT" | jq -r '.context_usage // empty')
  BODY="Finished<br>$PRETTY_CWD"
  [[ -n "$CONTEXT_USAGE" ]] && BODY+="<br>Context: $(echo "$CONTEXT_USAGE" | awk '{printf "%.0f%%", $1 * 100}')"
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
  notify-send --app-name="qwen-code" --app-icon="qwen-code" --icon="qwen-code" --hint=string:custom-sound:message "$TITLE" "$BODY"

elif command -v powershell.exe >/dev/null 2>&1; then
  # WSL / Windows
  powershell.exe -Command "[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms'); [System.Windows.Forms.MessageBox]::Show('$BODY', '$TITLE')"

else
  echo "No supported notification backend found (osascript/notify-send/powershell.exe)" >&2
fi

exit 0
