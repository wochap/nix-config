#!/usr/bin/env bash
#
# agy-notify.sh — Agy "Notification" hook
#
# Reads the hook's JSON payload from stdin and sends a custom desktop notification.

set -euo pipefail

INPUT=$(cat)
OUTPUT="{}"

WORKSPACE=$(echo "$INPUT" | jq -r '.workspacePaths[0] // ""')
PROJECT=$(basename "$WORKSPACE" 2>/dev/null || echo "project")

send_notification() {
  local TITLE=$1
  local BODY=$2

  if [[ "$OSTYPE" == "darwin"* ]]; then
    osascript -e "display notification \"$BODY\" with title \"$TITLE\""
  elif command -v notify-send >/dev/null 2>&1; then
    notify-send --app-name="agy" "$TITLE" "$BODY"
  elif command -v powershell.exe >/dev/null 2>&1; then
    powershell.exe -Command "[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms'); [System.Windows.Forms.MessageBox]::Show('$BODY', '$TITLE')"
  fi
}

# Check for PreToolUse
if echo "$INPUT" | jq -e '.toolCall' >/dev/null; then
  TOOL_NAME=$(echo "$INPUT" | jq -r '.toolCall.name')
  TOOL_ARGS=$(echo "$INPUT" | jq -r '.toolCall.args | tostring' | cut -c 1-120)

  send_notification "Agy needs permission ($PROJECT)" "$TOOL_NAME: $TOOL_ARGS"

  # 'ask' respects the "Always Allow" cache so it won't break normal behaviour
  OUTPUT='{"decision": "ask"}'
fi

# Check for Stop
if echo "$INPUT" | jq -e '.terminationReason' >/dev/null; then
  REASON=$(echo "$INPUT" | jq -r '.terminationReason')
  send_notification "Agy finished ($PROJECT)" "Reason: $REASON"

  OUTPUT='{"decision": "allow_stop"}'
fi

echo "$OUTPUT"
exit 0
