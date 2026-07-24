#!/usr/bin/env bash
#
# claude-notify.sh — Claude Code "Notification" hook
#
# Reads the hook's JSON payload from stdin and sends a custom desktop
# notification. Title carries the session name (from the transcript),
# body carries the message, pretty cwd, and — for permission prompts —
# the description of the tool call Claude wants to run.
#
# Install:
#   chmod +x claude-notify.sh
#   Put it somewhere like ~/.claude/hooks/claude-notify.sh
#
# Register in ~/.claude/settings.json (or .claude/settings.json for a
# single project):
#
# {
#   "hooks": {
#     "Notification": [
#       {
#         "matcher": "",
#         "hooks": [
#           { "type": "command", "command": "~/.claude/hooks/claude-notify.sh" }
#         ]
#       }
#     ]
#   }
# }
#
# matcher "" fires on every notification type. To only fire on specific
# types, set matcher to one of: permission_prompt, idle_prompt,
# auth_success, elicitation_dialog, elicitation_complete,
# elicitation_response, agent_needs_input, agent_completed

set -euo pipefail

INPUT=$(cat)

# Pull fields out of the JSON payload
EVENT=$(echo "$INPUT" | jq -r '.hook_event_name // ""')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
STATE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/claude-notify"

# PreToolUse: the Notification event fires *before* the pending tool_use
# is flushed to the transcript, so reading the transcript there yields the
# penultimate tool. Instead, record every attempted tool call here and let
# the Notification branch read it back.
if [[ "$EVENT" == "PreToolUse" ]]; then
  mkdir -p "$STATE_DIR"
  echo "$INPUT" | jq -r '
    if (.tool_input.description // "") != "" then "\(.tool_name): \(.tool_input.description)"
    elif .tool_name == "Bash" then "Bash: \(.tool_input.command // "" | .[0:120])"
    else .tool_name
    end' > "$STATE_DIR/last-tool-$SESSION_ID" 2>/dev/null || true
  exit 0
fi

MESSAGE=$(echo "$INPUT" | jq -r '.message // "Claude Code notification"')
TYPE=$(echo "$INPUT" | jq -r '.notification_type // "unknown"')
CWD=$(echo "$INPUT" | jq -r '.cwd // ""')
TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // ""')

# Pretty cwd: /home/gean/Projects/... -> ~/Projects/...
PRETTY_CWD="${CWD/#$HOME/\~}"
PROJECT=$(basename "$CWD" 2>/dev/null || echo "project")

# Session name: last ai-title / custom-title entry in the transcript.
# Renaming a session appends a new title line, so the last one wins.
SESSION_NAME=""
if [[ -n "$TRANSCRIPT" && -r "$TRANSCRIPT" ]]; then
  SESSION_NAME=$(tac "$TRANSCRIPT" 2>/dev/null |
    grep -m1 -oE '"(aiTitle|customTitle)":"([^"\\]|\\.)*"' |
    head -1 | sed -E 's/^"(aiTitle|customTitle)":"//; s/"$//') || true
fi

# Last tool call Claude attempted: prefer the PreToolUse state file (always
# current, even for the not-yet-flushed pending call); fall back to the
# transcript if the PreToolUse hook isn't registered.
LAST_TOOL=""
if [[ -r "$STATE_DIR/last-tool-$SESSION_ID" ]]; then
  LAST_TOOL=$(<"$STATE_DIR/last-tool-$SESSION_ID")
fi
if [[ -z "$LAST_TOOL" && -n "$TRANSCRIPT" && -r "$TRANSCRIPT" ]]; then
  LAST_TOOL=$(tail -n 400 "$TRANSCRIPT" 2>/dev/null | jq -rs '
    [ .[]
      | select(.type == "assistant")
      | .message.content[]?
      | select(.type == "tool_use")
    ] | last
    | if . == null then ""
      elif (.input.description // "") != "" then "\(.name): \(.input.description)"
      elif .name == "Bash" then "Bash: \(.input.command // "" | .[0:120])"
      else .name
      end' 2>/dev/null) || true
fi

# Build a custom title/body per notification type.
TITLE="${SESSION_NAME:-Claude Code}"
BODY="$MESSAGE"

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
  BODY="Ready for your next prompt.<br>$PRETTY_CWD"
  ;;
auth_success)
  BODY="Authentication succeeded."
  ;;
agent_completed)
  BODY="Background agent finished<br>$PRETTY_CWD"
  ;;
*)
  TITLE="Claude Code${SESSION_NAME:+ ($SESSION_NAME)} — $PROJECT"
  ;;
esac

# --- Send the notification (auto-detects OS) ---
if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS
  osascript -e "display notification \"$BODY\" with title \"$TITLE\""

elif command -v notify-send >/dev/null 2>&1; then
  # Linux (requires libnotify-bin: apt-get install libnotify-bin)
  notify-send --app-name="claude-code" --app-icon="claude-code" --icon="claude-code" --hint=string:custom-sound:message "$TITLE" "$BODY"

elif command -v powershell.exe >/dev/null 2>&1; then
  # WSL / Windows
  powershell.exe -Command "[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms'); [System.Windows.Forms.MessageBox]::Show('$BODY', '$TITLE')"

else
  echo "No supported notification backend found (osascript/notify-send/powershell.exe)" >&2
fi

# --- Optional: also/instead push to a webhook, e.g. ntfy.sh ---
# curl -s -d "$BODY" -H "Title: $TITLE" "https://ntfy.sh/your-topic-name" >/dev/null
#
# --- Optional: Slack webhook ---
# curl -s -X POST -H 'Content-type: application/json' \
#   --data "{\"text\":\"*$TITLE*\n$BODY\"}" \
#   "https://hooks.slack.com/services/XXX/YYY/ZZZ" >/dev/null

exit 0
