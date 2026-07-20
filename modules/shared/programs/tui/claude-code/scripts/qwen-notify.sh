#!/usr/bin/env bash
#
# qwen-notify.sh — Qwen Code desktop notification hook
#
# Reads the hook's JSON payload from stdin and sends a desktop notification
# when Qwen needs permission, is waiting for input, or finishes a turn.
#
# Install:
#   chmod +x ~/.qwen/hooks/qwen-notify.sh
#
# Register in ~/.qwen/settings.json:
#
# {
#   "hooks": {
#     "Notification": [
#       {
#         "matcher": "",
#         "hooks": [
#           { "type": "command", "command": "~/.qwen/hooks/qwen-notify.sh" }
#         ]
#       }
#     ],
#     "PreToolUse": [
#       {
#         "matcher": "",
#         "hooks": [
#           { "type": "command", "command": "~/.qwen/hooks/qwen-notify.sh", "async": true }
#         ]
#       }
#     ],
#     "Stop": [
#       {
#         "hooks": [
#           { "type": "command", "command": "~/.qwen/hooks/qwen-notify.sh", "async": true }
#         ]
#       }
#     ]
#   }
# }

set -euo pipefail

INPUT=$(cat)

EVENT=$(echo "$INPUT" | jq -r '.hook_event_name // ""')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
STATE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/qwen-notify"

# --- PreToolUse: record the last tool Qwen attempted ---
if [[ "$EVENT" == "PreToolUse" ]]; then
  mkdir -p "$STATE_DIR"
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
    end' >"$STATE_DIR/last-tool-$SESSION_ID" 2>/dev/null || true
  exit 0
fi

# --- Stop: Qwen finished its turn ---
if [[ "$EVENT" == "Stop" ]]; then
  CWD=$(echo "$INPUT" | jq -r '.cwd // ""')
  PRETTY_CWD="${CWD/#$HOME/\~}"
  PROJECT=$(basename "$CWD" 2>/dev/null || echo "project")

  TITLE="Qwen Code — $PROJECT"
  BODY="Qwen finished its turn<br>$PRETTY_CWD"

  LAST_TOOL=""
  if [[ -r "$STATE_DIR/last-tool-$SESSION_ID" ]]; then
    LAST_TOOL=$(<"$STATE_DIR/last-tool-$SESSION_ID")
  fi
  [[ -n "$LAST_TOOL" ]] && BODY+="<br><i>$LAST_TOOL</i>"

  if command -v notify-send >/dev/null 2>&1; then
    notify-send --app-name="qwen-code" --urgency=normal "$TITLE" "$BODY"
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    osascript -e "display notification \"$BODY\" with title \"$TITLE\""
  fi
  exit 0
fi

# --- Notification event ---
MESSAGE=$(echo "$INPUT" | jq -r '.message // "Qwen Code notification"')
TYPE=$(echo "$INPUT" | jq -r '.notification_type // "unknown"')
CWD=$(echo "$INPUT" | jq -r '.cwd // ""')

PRETTY_CWD="${CWD/#$HOME/\~}"
PROJECT=$(basename "$CWD" 2>/dev/null || echo "project")

TITLE="Qwen Code — $PROJECT"
BODY="$MESSAGE"

# Last tool Qwen attempted
LAST_TOOL=""
if [[ -r "$STATE_DIR/last-tool-$SESSION_ID" ]]; then
  LAST_TOOL=$(<"$STATE_DIR/last-tool-$SESSION_ID")
fi

case "$TYPE" in
permission_prompt)
  BODY="Qwen needs your permission<br>$PRETTY_CWD"
  [[ -n "$LAST_TOOL" ]] && BODY+="<br><i>$LAST_TOOL</i>"
  URGENCY="critical"
  ;;
idle_prompt)
  BODY="Qwen is ready for your next prompt<br>$PRETTY_CWD"
  URGENCY="normal"
  ;;
auth_success)
  BODY="Authentication succeeded."
  URGENCY="low"
  ;;
*)
  BODY="$MESSAGE<br>$PRETTY_CWD"
  URGENCY="normal"
  ;;
esac

# --- Send the notification ---
if command -v notify-send >/dev/null 2>&1; then
  notify-send --app-name="qwen-code" --urgency="$URGENCY" "$TITLE" "$BODY"
elif [[ "$OSTYPE" == "darwin"* ]]; then
  osascript -e "display notification \"$BODY\" with title \"$TITLE\""
elif command -v powershell.exe >/dev/null 2>&1; then
  powershell.exe -Command "[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms'); [System.Windows.Forms.MessageBox]::Show('$BODY', '$TITLE')"
else
  echo "No supported notification backend found" >&2
fi

exit 0
