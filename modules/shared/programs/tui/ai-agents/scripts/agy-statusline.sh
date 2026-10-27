#!/bin/bash
# Custom Antigravity CLI (agy) statusline.
# Format: [MODE] [VIM] · Model [Effort] · dir · branch · Context X% used · N in · M out · artifacts · subagents · tasks · SessionID
# Follows default CLI theme (muted grey with subtle accents).

INPUT=$(cat)

# Extract fields from agy state JSON (each field outputs exactly 1 line)
{
  read -r MODEL
  read -r EFFORT
  read -r MODE
  read -r VIM_MODE
  read -r AGENT_STATE
  read -r DIR
  read -r BRANCH_IN
  read -r DIRTY_IN
  read -r CTX_PCT
  read -r TOK_IN
  read -r TOK_OUT
  read -r ARTIFACTS
  read -r SUBAGENTS
  read -r TASKS
  read -r CONV_ID
} <<< "$(
  printf '%s' "$INPUT" | jq -r '
    (.model.display_name // .model.id // "?"),
    (.effort // .effort.level // ""),
    (.permission_mode // .agent_mode // .agentMode // .mode // ""),
    (.vim.mode // ""),
    (.agent_state // ""),
    (.cwd // .workspace.current_dir // "?"),
    (.vcs.branch // ""),
    (if .vcs.dirty == true then "true" else "false" end),
    (if (.context_window.used_percentage | type == "number") then
      ((.context_window.used_percentage * 10 | round) / 10 | tostring)
    else
      ""
    end),
    (if (.context_window.total_input_tokens | type == "number") and .context_window.total_input_tokens > 0 then
      .context_window.total_input_tokens
    else
      (.context_window.current_usage.input_tokens // 0)
    end),
    (if (.context_window.total_output_tokens | type == "number") and .context_window.total_output_tokens > 0 then
      .context_window.total_output_tokens
    else
      (.context_window.current_usage.output_tokens // 0)
    end),
    (.artifact_count // 0),
    (if .subagents | type == "array" then (.subagents | length) else 0 end),
    (.task_count // 0),
    (.conversation_id // "")
  ' 2>/dev/null || printf "?\n\n\n\n\n?\n\nfalse\n\n0\n0\n0\n0\n0\n\n"
)"

# Fallback for MODE from settings if omitted in payload
if [ -z "$MODE" ]; then
  SETTINGS_FILE="$HOME/.gemini/antigravity-cli/settings.json"
  if [ -f "$SETTINGS_FILE" ]; then
    MODE=$(jq -r '.mode // empty' "$SETTINGS_FILE" 2>/dev/null || true)
  fi
  [ -z "$MODE" ] && MODE="auto"
fi

# Styling: Theme-matching muted grey and subtle accents
RESET="\033[0m"
GREY="\033[38;5;244m"     # Muted grey base text
DARK_GREY="\033[90m"      # Dim grey for brackets/separators
GREEN="\033[32m"
YELLOW="\033[33m"
MAGENTA="\033[35m"
BLUE="\033[34m"
RED="\033[31m"
SEP="${DARK_GREY} · ${GREY}"

# Format a raw token count with a unit suffix: 2 -> 2, 15300 -> 15.3k, 2400000 -> 2.4M
humanize() {
  awk -v n="$1" 'BEGIN {
    if (n >= 1000000) printf "%.1fM", n / 1000000
    else if (n >= 1000) printf "%.1fk", n / 1000
    else printf "%d", n
  }'
}

DIRNAME=$(basename "$DIR")

BRANCH="$BRANCH_IN"
DIRTY="$DIRTY_IN"
if git -C "$DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  TOPLEVEL=$(git -C "$DIR" rev-parse --show-toplevel 2>/dev/null)
  [ -n "$TOPLEVEL" ] && DIRNAME=$(basename "$TOPLEVEL")
  CURRENT_BRANCH=$(git -C "$DIR" branch --show-current 2>/dev/null)
  [ -n "$CURRENT_BRANCH" ] && BRANCH="$CURRENT_BRANCH"
  if [ "$DIRTY" != "true" ]; then
    if [ -n "$(git -C "$DIR" status --porcelain -uno 2>/dev/null)" ]; then
      DIRTY="true"
    fi
  fi
fi

PARTS=()

# 1. Permission / Execution Mode Badge
if [ -n "$MODE" ]; then
  case "$MODE" in
    auto)         PARTS+=("${GREEN}[auto]${GREY}") ;;
    plan)         PARTS+=("${YELLOW}[plan]${GREY}") ;;
    accept-edits) PARTS+=("${MAGENTA}[accept-edits]${GREY}") ;;
    *)            PARTS+=("${DARK_GREY}[${MODE}]${GREY}") ;;
  esac
fi

# 2. Vim Mode Badge (if enabled)
if [ -n "$VIM_MODE" ]; then
  case "$VIM_MODE" in
    NORMAL)  PARTS+=("${BLUE}[NORMAL]${GREY}") ;;
    INSERT)  PARTS+=("${GREEN}[INSERT]${GREY}") ;;
    VISUAL*) PARTS+=("${MAGENTA}[${VIM_MODE}]${GREY}") ;;
    *)       PARTS+=("${DARK_GREY}[${VIM_MODE}]${GREY}") ;;
  esac
fi

# 3. Agent State (if actively working/thinking, not idle)
if [ -n "$AGENT_STATE" ] && [ "$AGENT_STATE" != "idle" ] && [ "$AGENT_STATE" != "ready" ]; then
  PARTS+=("${YELLOW}${AGENT_STATE}${GREY}")
fi

# 4. Model & Effort
MODEL_PART="$MODEL"
if [ -n "$EFFORT" ] && [[ "$MODEL" != *"$EFFORT"* ]]; then
  MODEL_PART="$MODEL_PART $EFFORT"
fi
PARTS+=("$MODEL_PART")

# 5. Directory
PARTS+=("$DIRNAME")

# 6. Git Branch with dirty indicator
if [ -n "$BRANCH" ]; then
  if [ "$DIRTY" = "true" ]; then
    PARTS+=("${BRANCH}${RED}*${GREY}")
  else
    PARTS+=("$BRANCH")
  fi
fi

# 7. Context % used (with soft warnings at high percentages)
if [ -n "$CTX_PCT" ]; then
  PCT_NUM="${CTX_PCT%.*}"
  if [ "${PCT_NUM:-0}" -ge 90 ] 2>/dev/null; then
    PARTS+=("${RED}Context ${CTX_PCT}% used${GREY}")
  elif [ "${PCT_NUM:-0}" -ge 75 ] 2>/dev/null; then
    PARTS+=("${YELLOW}Context ${CTX_PCT}% used${GREY}")
  else
    PARTS+=("Context ${CTX_PCT}% used")
  fi
fi

# 8. Token counts
PARTS+=("$(humanize "$TOK_IN") in")
PARTS+=("$(humanize "$TOK_OUT") out")

# 9. Artifacts (if any)
if [ "${ARTIFACTS:-0}" -gt 0 ] 2>/dev/null; then
  PARTS+=("${ARTIFACTS} artifacts")
fi

# 10. Subagents (if any)
if [ "${SUBAGENTS:-0}" -gt 0 ] 2>/dev/null; then
  PARTS+=("${SUBAGENTS} subagents")
fi

# 11. Tasks (if any)
if [ "${TASKS:-0}" -gt 0 ] 2>/dev/null; then
  PARTS+=("${TASKS} tasks")
fi

# 12. Session / Conversation ID prefix
[ -n "$CONV_ID" ] && PARTS+=("${CONV_ID:0:8}")

LINE=""
for p in "${PARTS[@]}"; do
  if [ -z "$LINE" ]; then
    LINE="$p"
  else
    LINE="${LINE}${SEP}${p}"
  fi
done

printf "${GREY}%b${RESET}\n" "$LINE"
