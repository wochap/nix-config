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

# Last tool call Claude attempted: tool name + its `description` input
# (Bash calls always carry a short human summary there).
LAST_TOOL=""
if [[ -n "$TRANSCRIPT" && -r "$TRANSCRIPT" ]]; then
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
TITLE="Claude Code${SESSION_NAME:+ ($SESSION_NAME)}"
BODY="$MESSAGE"

case "$TYPE" in
permission_prompt)
  BODY="Claude needs your permission"$'\n'"$PRETTY_CWD"
  [[ -n "$LAST_TOOL" ]] && BODY+=$'\n'"($LAST_TOOL)"
  ;;
agent_needs_input)
  BODY="Claude is waiting for your input"$'\n'"$PRETTY_CWD"
  [[ -n "$LAST_TOOL" ]] && BODY+=$'\n'"($LAST_TOOL)"
  ;;
idle_prompt)
  BODY="Ready for your next prompt."$'\n'"$PRETTY_CWD"
  ;;
auth_success)
  BODY="Authentication succeeded."
  ;;
agent_completed)
  BODY="Background agent finished"$'\n'"$PRETTY_CWD"
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
  notify-send --app-name="claude-code" --hint=string:custom-sound:message "$TITLE" "$BODY"

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
