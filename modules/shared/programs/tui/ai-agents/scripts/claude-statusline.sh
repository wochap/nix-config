#!/bin/bash
# Custom Claude Code statusline.
# Format: [CAVEMAN:LEVEL] · Model Effort · dir · branch · Context X% used · N in · M out · SessionName
# Token counts are session totals (whole transcript), not just the last API call.

INPUT=$(cat)

MODEL=$(printf '%s' "$INPUT" | jq -r '.model.display_name // "?"')
EFFORT=$(printf '%s' "$INPUT" | jq -r '.effort.level // empty')
DIR=$(printf '%s' "$INPUT" | jq -r '.workspace.current_dir // .cwd // "?"')
CTX_PCT=$(printf '%s' "$INPUT" | jq -r 'if .context_window.used_percentage != null then (.context_window.used_percentage | tostring) else empty end')
TRANSCRIPT=$(printf '%s' "$INPUT" | jq -r '.transcript_path // empty')

# Session totals, summed over the transcript. context_window.current_usage only
# covers the last API call, so it can't be used here. Assistant rows repeat for a
# single API call, so dedupe on message.id before summing.
TOK_IN=0
TOK_OUT=0
if [ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ]; then
  # Re-scanning a long transcript on every render is slow, so cache the totals
  # and reuse them until the file grows.
  CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/claude-statusline"
  CACHE_FILE="$CACHE_DIR/$(basename "$TRANSCRIPT").totals"
  SIZE=$(wc -c < "$TRANSCRIPT" 2>/dev/null || echo 0)
  CACHED=$(cat "$CACHE_FILE" 2>/dev/null)

  if [ "${CACHED%% *}" = "$SIZE" ] && [ -n "$CACHED" ]; then
    read -r _ TOK_IN TOK_OUT <<< "$CACHED"
  else
    TOTALS=$(jq -n -r '
      reduce (inputs | select(.message.usage != null)) as $l
        ({seen: {}, tin: 0, tout: 0};
          ($l.message.id // $l.requestId // "?") as $id
          | if .seen[$id] then .
            else
              .seen[$id] = true
              | .tin += (($l.message.usage.input_tokens // 0)
                       + ($l.message.usage.cache_read_input_tokens // 0)
                       + ($l.message.usage.cache_creation_input_tokens // 0))
              | .tout += ($l.message.usage.output_tokens // 0)
            end)
      | "\(.tin) \(.tout)"' "$TRANSCRIPT" 2>/dev/null)
    if [ -n "$TOTALS" ]; then
      read -r TOK_IN TOK_OUT <<< "$TOTALS"
      mkdir -p "$CACHE_DIR" 2>/dev/null && printf '%s %s %s\n' "$SIZE" "$TOK_IN" "$TOK_OUT" > "$CACHE_FILE" 2>/dev/null
    fi
  fi
fi

# Format a raw token count with a unit suffix: 2 -> 2, 15300 -> 15.3k, 2400000 -> 2.4M
humanize() {
  awk -v n="$1" 'BEGIN {
    if (n >= 1000000) printf "%.1fM", n / 1000000
    else if (n >= 1000) printf "%.1fk", n / 1000
    else printf "%d", n
  }'
}
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
PARTS+=("$(humanize "$TOK_IN") in")
PARTS+=("$(humanize "$TOK_OUT") out")
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
