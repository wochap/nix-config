#!/bin/bash
# Custom Claude Code statusline.
# Format: [CAVEMAN:LEVEL] · Model Effort · dir · branch · Context X% used · N in · M out · SessionName

INPUT=$(cat)

MODEL=$(printf '%s' "$INPUT" | jq -r '.model.display_name // "?"')
EFFORT=$(printf '%s' "$INPUT" | jq -r '.effort.level // empty')
DIR=$(printf '%s' "$INPUT" | jq -r '.workspace.current_dir // .cwd // "?"')
CTX_PCT=$(printf '%s' "$INPUT" | jq -r 'if .context_window.used_percentage != null then (.context_window.used_percentage | tostring) else empty end')
TOK_IN=$(printf '%s' "$INPUT" | jq -r '.context_window.current_usage.input_tokens // 0')
TOK_OUT=$(printf '%s' "$INPUT" | jq -r '.context_window.current_usage.output_tokens // 0')
SESSION_NAME=$(printf '%s' "$INPUT" | jq -r '.session_name // empty')

DIRNAME=$(basename "$DIR")

BRANCH=""
if git -C "$DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  TOPLEVEL=$(git -C "$DIR" rev-parse --show-toplevel 2>/dev/null)
  [ -n "$TOPLEVEL" ] && DIRNAME=$(basename "$TOPLEVEL")
  BRANCH=$(git -C "$DIR" branch --show-current 2>/dev/null)
fi

CAVEMAN_SCRIPT="/home/gean/.claude/plugins/cache/caveman/caveman/0d95a81d35a9/src/hooks/caveman-statusline.sh"
CAVEMAN_OUT=""
if [ -f "$CAVEMAN_SCRIPT" ]; then
  CAVEMAN_OUT=$(bash "$CAVEMAN_SCRIPT")
fi

SEP=" · "
PARTS=()

MODEL_PART="$MODEL"
[ -n "$EFFORT" ] && MODEL_PART="$MODEL_PART $EFFORT"
PARTS+=("$MODEL_PART")

PARTS+=("$DIRNAME")
[ -n "$BRANCH" ] && PARTS+=("$BRANCH")
[ -n "$CTX_PCT" ] && PARTS+=("Context ${CTX_PCT}% used")
PARTS+=("${TOK_IN} in")
PARTS+=("${TOK_OUT} out")
[ -n "$SESSION_NAME" ] && PARTS+=("$SESSION_NAME")

LINE=""
for p in "${PARTS[@]}"; do
  if [ -z "$LINE" ]; then
    LINE="$p"
  else
    LINE="$LINE$SEP$p"
  fi
done

if [ -n "$CAVEMAN_OUT" ]; then
  printf '%s%s%s\n' "$CAVEMAN_OUT" "$SEP" "$LINE"
else
  printf '%s\n' "$LINE"
fi
