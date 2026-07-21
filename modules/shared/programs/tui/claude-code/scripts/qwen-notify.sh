#!/usr/bin/env bash
#
# qwen-notify.sh — Qwen Code desktop notification hook
#
# Reads the hook's JSON payload from stdin and sends a desktop notification.
# Handles: permission requests, idle/waiting, turn completion, session
# lifecycle, subagent completion, API errors, and todo progress.
#
# Install:
#   chmod +x ~/.qwen/hooks/qwen-notify.sh
#
# Register in ~/.qwen/settings.json:
#
# {
#   "hooks": {
#     "Notification": [
#       { "matcher": "", "hooks": [{ "type": "command", "command": "~/.qwen/hooks/qwen-notify.sh" }] }
#     ],
#     "PermissionRequest": [
#       { "matcher": "", "hooks": [{ "type": "command", "command": "~/.qwen/hooks/qwen-notify.sh" }] }
#     ],
#     "PreToolUse": [
#       { "matcher": "", "hooks": [{ "type": "command", "command": "~/.qwen/hooks/qwen-notify.sh", "async": true }] }
#     ],
#     "Stop": [
#       { "hooks": [{ "type": "command", "command": "~/.qwen/hooks/qwen-notify.sh", "async": true }] }
#     ],
#     "StopFailure": [
#       { "matcher": "", "hooks": [{ "type": "command", "command": "~/.qwen/hooks/qwen-notify.sh" }] }
#     ],
#     "SessionStart": [
#       { "matcher": "", "hooks": [{ "type": "command", "command": "~/.qwen/hooks/qwen-notify.sh", "async": true }] }
#     ],
#     "SessionEnd": [
#       { "matcher": "", "hooks": [{ "type": "command", "command": "~/.qwen/hooks/qwen-notify.sh", "async": true }] }
#     ],
#     "SubagentStop": [
#       { "matcher": "", "hooks": [{ "type": "command", "command": "~/.qwen/hooks/qwen-notify.sh", "async": true }] }
#     ]
#   }
# }

set -euo pipefail

INPUT=$(cat)

EVENT=$(echo "$INPUT" | jq -r '.hook_event_name // ""')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
STATE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/qwen-notify"

# --- Helper: send notification ---
notify() {
  local title="$1" body="$2" urgency="${3:-normal}"

  if command -v notify-send >/dev/null 2>&1; then
    notify-send --app-name="qwen-code" --app-icon="qwen-code" ---icon="qwen-code" --urgency="$urgency" --hint=string:custom-sound:message "$title" "$body"
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    osascript -e "display notification \"$body\" with title \"$title\""
  elif command -v powershell.exe >/dev/null 2>&1; then
    powershell.exe -Command "[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms'); [System.Windows.Forms.MessageBox]::Show('$body', '$title')"
  else
    echo "qwen-notify: no notification backend found" >&2
  fi
}

# --- Helper: pretty cwd ---
pretty_cwd() {
  local cwd="$1"
  echo "${cwd/#$HOME/\~}"
}

# --- Helper: project name from cwd ---
project_name() {
  basename "$1" 2>/dev/null || echo "project"
}

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

# --- Helper: read last tool from state ---
last_tool() {
  local f="$STATE_DIR/last-tool-$SESSION_ID"
  [[ -r "$f" ]] && cat "$f" || echo ""
}

# ============================================================
# PreToolUse: record the tool Qwen is about to run (silent)
# ============================================================
if [[ "$EVENT" == "PreToolUse" ]]; then
  mkdir -p "$STATE_DIR"
  describe_tool >"$STATE_DIR/last-tool-$SESSION_ID" 2>/dev/null || true
  exit 0
fi

# ============================================================
# PermissionRequest: Qwen needs approval for a tool call
# ============================================================
if [[ "$EVENT" == "PermissionRequest" ]]; then
  CWD=$(echo "$INPUT" | jq -r '.cwd // ""')
  TOOL_DESC=$(describe_tool)
  PROJECT=$(project_name "$CWD")

  TITLE="Qwen Code — $PROJECT"
  BODY="⚠️ Permission needed\n$(pretty_cwd "$CWD")"
  [[ -n "$TOOL_DESC" ]] && BODY+="\n$TOOL_DESC"

  notify "$TITLE" "$BODY" "critical"
  exit 0
fi

# ============================================================
# Notification: permission_prompt, idle_prompt, auth_success
# ============================================================
if [[ "$EVENT" == "Notification" ]]; then
  MESSAGE=$(echo "$INPUT" | jq -r '.message // "Qwen Code notification"')
  TYPE=$(echo "$INPUT" | jq -r '.notification_type // "unknown"')
  CWD=$(echo "$INPUT" | jq -r '.cwd // ""')
  PRETTY=$(pretty_cwd "$CWD")
  PROJECT=$(project_name "$CWD")
  TOOL=$(last_tool)

  TITLE="Qwen Code — $PROJECT"
  URGENCY="normal"

  case "$TYPE" in
  permission_prompt)
    BODY="⚠️ Qwen needs your permission\n$PRETTY"
    [[ -n "$TOOL" ]] && BODY+="\n$TOOL"
    URGENCY="critical"
    ;;
  idle_prompt)
    BODY="💬 Ready for your next prompt\n$PRETTY"
    ;;
  auth_success)
    BODY="✅ Authentication succeeded"
    URGENCY="low"
    ;;
  *)
    BODY="$MESSAGE\n$PRETTY"
    ;;
  esac

  notify "$TITLE" "$BODY" "$URGENCY"
  exit 0
fi

# ============================================================
# Stop: Qwen finished its turn
# ============================================================
if [[ "$EVENT" == "Stop" ]]; then
  CWD=$(echo "$INPUT" | jq -r '.cwd // ""')
  CONTEXT_USAGE=$(echo "$INPUT" | jq -r '.context_usage // empty')
  PROJECT=$(project_name "$CWD")
  TOOL=$(last_tool)

  TITLE="Qwen Code — $PROJECT"
  BODY="✅ Finished\n$(pretty_cwd "$CWD")"
  [[ -n "$TOOL" ]] && BODY+="\nLast: $TOOL"
  [[ -n "$CONTEXT_USAGE" ]] && BODY+="\nContext: $(echo "$CONTEXT_USAGE" | awk '{printf "%.0f%%", $1 * 100}')"

  notify "$TITLE" "$BODY" "normal"
  exit 0
fi

# ============================================================
# StopFailure: turn ended due to API error
# ============================================================
if [[ "$EVENT" == "StopFailure" ]]; then
  CWD=$(echo "$INPUT" | jq -r '.cwd // ""')
  PROJECT=$(project_name "$CWD")

  TITLE="Qwen Code — $PROJECT"
  BODY="❌ Stopped due to an error\n$(pretty_cwd "$CWD")"

  notify "$TITLE" "$BODY" "critical"
  exit 0
fi

# ============================================================
# SessionStart: session started/resumed
# ============================================================
if [[ "$EVENT" == "SessionStart" ]]; then
  CWD=$(echo "$INPUT" | jq -r '.cwd // ""')
  SOURCE=$(echo "$INPUT" | jq -r '.source // "startup"')
  MODEL=$(echo "$INPUT" | jq -r '.model // ""')
  PROJECT=$(project_name "$CWD")

  TITLE="Qwen Code — $PROJECT"
  BODY="🚀 Session ${SOURCE}\n$(pretty_cwd "$CWD")"
  [[ -n "$MODEL" ]] && BODY+="\nModel: $MODEL"

  notify "$TITLE" "$BODY" "low"
  exit 0
fi

# ============================================================
# SessionEnd: session ended
# ============================================================
if [[ "$EVENT" == "SessionEnd" ]]; then
  CWD=$(echo "$INPUT" | jq -r '.cwd // ""')
  REASON=$(echo "$INPUT" | jq -r '.reason // "unknown"')
  PROJECT=$(project_name "$CWD")

  TITLE="Qwen Code — $PROJECT"
  BODY="👋 Session ended ($REASON)\n$(pretty_cwd "$CWD")"

  notify "$TITLE" "$BODY" "low"
  exit 0
fi

# ============================================================
# SubagentStop: a background agent finished
# ============================================================
if [[ "$EVENT" == "SubagentStop" ]]; then
  CWD=$(echo "$INPUT" | jq -r '.cwd // ""')
  AGENT_TYPE=$(echo "$INPUT" | jq -r '.agent_type // "agent"')
  PROJECT=$(project_name "$CWD")

  TITLE="Qwen Code — $PROJECT"
  BODY="🤖 Subagent ($AGENT_TYPE) finished\n$(pretty_cwd "$CWD")"

  notify "$TITLE" "$BODY" "normal"
  exit 0
fi

# ============================================================
# Fallback: unknown event
# ============================================================
CWD=$(echo "$INPUT" | jq -r '.cwd // ""')
PROJECT=$(project_name "$CWD")
notify "Qwen Code — $PROJECT" "Event: $EVENT\n$(pretty_cwd "$CWD")" "low"

exit 0
