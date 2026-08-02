#!/usr/bin/env bash
#
# agy-notify.sh — Agy "Notification" hook
#
# Reads the hook's JSON payload from stdin and sends a custom desktop notification.

set -euo pipefail

INPUT=$(cat)
OUTPUT="{}"

# --- Extract common fields ---
WORKSPACE=$(echo "$INPUT" | jq -r '.workspacePaths[0] // .cwd // ""')
if [[ -z "$WORKSPACE" ]]; then
  WORKSPACE="$PWD"
fi
PRETTY_CWD="${WORKSPACE/#$HOME/\~}"

# Attempt to get a session title (from possible fields in agy payload)
SESSION_TITLE=$(echo "$INPUT" | jq -r '.sessionTitle // .conversationName // .title // empty' 2>/dev/null || true)
TITLE="${SESSION_TITLE:-Antigravity CLI}"

BODY=""

# --- Helper: format tool description ---
format_tool() {
  local tool_name=$1
  local tool_args=$2

  if [[ "$tool_name" == "run_command" ]]; then
    echo "shell: $(echo "$tool_args" | jq -r '.CommandLine // .command // ""' | cut -c 1-50)"
  elif [[ "$tool_name" == "write_to_file" || "$tool_name" == "replace_file_content" || "$tool_name" == "multi_replace_file_content" ]]; then
    local file=$(echo "$tool_args" | jq -r '.TargetFile // .file_path // ""' | awk -F/ '{print $NF}')
    echo "edit: $file"
  else
    # Output raw JSON args but strictly shortened
    echo "$tool_name: $(echo "$tool_args" | jq -c '.' | cut -c 1-50)"
  fi
}

# Check for PreToolUse
if echo "$INPUT" | jq -e '.toolCall' >/dev/null; then
  TOOL_NAME=$(echo "$INPUT" | jq -r '.toolCall.name')
  TOOL_ARGS=$(echo "$INPUT" | jq -c '.toolCall.args')

  TOOL_DESC=$(format_tool "$TOOL_NAME" "$TOOL_ARGS")

  if [[ "$TOOL_NAME" == "ask_question" || "$TOOL_NAME" == "ask_permission" ]]; then
    BODY="Agy is waiting for your input<br>$TOOL_DESC...<br>$PRETTY_CWD"
    OUTPUT='{"decision": "allow"}'
  else
    BODY="Agy needs permission<br>$TOOL_DESC...<br>$PRETTY_CWD"
    OUTPUT='{"decision": "ask"}'
  fi

# Check for Stop
elif echo "$INPUT" | jq -e '.terminationReason' >/dev/null; then
  REASON=$(echo "$INPUT" | jq -r '.terminationReason')
  ERROR_MSG=$(echo "$INPUT" | jq -r '.error // empty')

  if [[ "$REASON" == "error" || -n "$ERROR_MSG" ]]; then
    BODY="Stopped due to an error<br>${ERROR_MSG:0:50}...<br>$PRETTY_CWD"
  else
    BODY="Finished<br>Reason: $REASON<br>$PRETTY_CWD"
  fi
  OUTPUT='{"decision": "allow_stop"}'
else
  BODY="Agy notification<br>$PRETTY_CWD"
fi

# Add additional useful info if available (e.g. token usage or cost)
TOKENS=$(echo "$INPUT" | jq -r '.usage.totalTokens // empty')
if [[ -n "$TOKENS" ]]; then
  BODY+="<br>Tokens used: $TOKENS"
fi

send_notification() {
  local TITLE=$1
  local BODY=$2

  if [[ "$OSTYPE" == "darwin"* ]]; then
    osascript -e "display notification \"$BODY\" with title \"$TITLE\""
  elif command -v notify-send >/dev/null 2>&1; then
    notify-send --app-name="agy-cli" --app-icon="agy-cli" --icon="agy-cli" --hint=string:custom-sound:message  "$TITLE" "$BODY"
  elif command -v powershell.exe >/dev/null 2>&1; then
    # PowerShell requires escaping newlines or joining them for MessageBox
    local PS_BODY=$(echo "$BODY" | tr '\n' ' ')
    powershell.exe -Command "[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms'); [System.Windows.Forms.MessageBox]::Show('$PS_BODY', '$TITLE')"
  fi
}

send_notification "$TITLE" "$BODY"

echo "$OUTPUT"
exit 0
