#!/bin/bash
# Custom Antigravity CLI (agy) statusline.
# Format: Model [Effort] · dir · branch · Context X% used · N in · M out · SessionID
# Inspired by claude-statusline.sh

INPUT=$(cat)

# Extract fields from agy state JSON (must always output a line per field, so use "" instead of empty)
{
  read -r MODEL
  read -r EFFORT
  read -r DIR
  read -r BRANCH_IN
  read -r CTX_PCT
  read -r TOK_IN
  read -r TOK_OUT
  read -r CONV_ID
} <<< "$(
  printf '%s' "$INPUT" | jq -r '
    (.model.display_name // .model.id // "?"),
    (.effort // .effort.level // ""),
    (.cwd // .workspace.current_dir // "?"),
    (.vcs.branch // ""),
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
    (.conversation_id // "")
  ' 2>/dev/null || printf "?\n\n?\n\n\n0\n0\n\n"
)"

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
if git -C "$DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  TOPLEVEL=$(git -C "$DIR" rev-parse --show-toplevel 2>/dev/null)
  [ -n "$TOPLEVEL" ] && DIRNAME=$(basename "$TOPLEVEL")
  CURRENT_BRANCH=$(git -C "$DIR" branch --show-current 2>/dev/null)
  [ -n "$CURRENT_BRANCH" ] && BRANCH="$CURRENT_BRANCH"
fi

SEP=" · "
PARTS=()

MODEL_PART="$MODEL"
if [ -n "$EFFORT" ] && [[ "$MODEL" != *"$EFFORT"* ]]; then
  MODEL_PART="$MODEL_PART $EFFORT"
fi
PARTS+=("$MODEL_PART")

PARTS+=("$DIRNAME")
[ -n "$BRANCH" ] && PARTS+=("$BRANCH")
[ -n "$CTX_PCT" ] && PARTS+=("Context ${CTX_PCT}% used")
PARTS+=("$(humanize "$TOK_IN") in")
PARTS+=("$(humanize "$TOK_OUT") out")
[ -n "$CONV_ID" ] && PARTS+=("${CONV_ID:0:8}")

LINE=""
for p in "${PARTS[@]}"; do
  if [ -z "$LINE" ]; then
    LINE="$p"
  else
    LINE="$LINE$SEP$p"
  fi
done

printf '%s\n' "$LINE"
