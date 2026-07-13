#!/usr/bin/env bash
#
# claude-notify.sh — Claude Code "Notification" hook
#
# Reads the hook's JSON payload from stdin and sends a custom desktop
# notification. Customize the CASE block below to change the title/message
# per notification type, or wire in a webhook (Slack/Discord/ntfy) instead
# of a desktop popup — see the commented example at the bottom.
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
#           { "type": "command", "command": "path/to/claude-notify.sh" }
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
PROJECT=$(basename "$CWD" 2>/dev/null || echo "project")

# Build a custom title/body per notification type. Edit these to taste.
TITLE="Claude Code"
BODY="$MESSAGE"

case "$TYPE" in
permission_prompt)
  TITLE="Claude needs permission — $PROJECT"
  BODY="Approve or deny: $MESSAGE"
  ;;
idle_prompt)
  TITLE="Claude is waiting — $PROJECT"
  BODY="Ready for your next prompt."
  ;;
auth_success)
  TITLE="Claude Code"
  BODY="Authentication succeeded."
  ;;
agent_needs_input)
  TITLE="Background agent needs input — $PROJECT"
  BODY="$MESSAGE"
  ;;
agent_completed)
  TITLE="Background agent finished — $PROJECT"
  BODY="$MESSAGE"
  ;;
*)
  TITLE="Claude Code — $PROJECT"
  BODY="$MESSAGE"
  ;;
esac

# --- Send the notification (auto-detects OS) ---
if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS
  osascript -e "display notification \"$BODY\" with title \"$TITLE\""

elif command -v notify-send >/dev/null 2>&1; then
  # Linux (requires libnotify-bin: apt-get install libnotify-bin)
  notify-send "$TITLE" "$BODY"

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
