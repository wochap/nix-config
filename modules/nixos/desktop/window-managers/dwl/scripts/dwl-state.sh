#!/usr/bin/env bash
#
# inspiration: https://gitee.com/guyuming76/personal/blob/dwl/gentoo/waybar-dwl/waybar-dwl.sh
# NOTE: `mode` requires the following patch https://github.com/djpohly/dwl/wiki/modes
#
# dwl-status.sh - display dwl tags, layout, selmon, active mode, active window title, namedscratchpads_count, scratchpads_count and visible_appids
#   Based heavily upon this script by user "novakane" (Hugo Machet) used to do the same for yambar
#   https://codeberg.org/novakane/yambar/src/branch/master/examples/scripts/dwl-tags.sh
#
# USAGE: waybar-dwl.sh MONITOR COMPONENT
#        "COMPONENT" is an integer representing a dwl tag OR "layout" OR "selmon" OR "title" OR "mode" OR "namedscratchpads_count" or "scratchpads_count" or "visible_appids"
#
# REQUIREMENTS:
#  - inotifywait ( 'inotify-tools' on arch )
#  - Launch dwl with `dwl > ~.cache/dwl/logs` or change $fname

set -euo pipefail

# Configuration
readonly FILE_PATH="${HOME}/.cache/dwl/logs"
readonly TAIL_LINES=200  # Number of lines to scan from the log file
declare -a TAG_LABELS=("1" "2" "3" "4" "5" "6" "7" "8" "9")

# Parse arguments
monitor="${1:-}"
component="${2:-}"
once_mode="${3:-}"

if [[ ! -f "$FILE_PATH" ]]; then
  echo "You need to redirect dwl stdout to $FILE_PATH" >&2
fi

last_val=""

cycle() {
  local file tags occupiedtags activatedtags focusedtags urgenttags
  local mask this_status val this_tag

  # Read the last TAIL_LINES lines and reverse the order so the newest events come first.
  file=$(tail -n "$TAIL_LINES" "$FILE_PATH" | tac)

  case "$component" in
    [0-8])
      # Match a line starting with the monitor (or a generic pattern if empty) followed by "tags"
      tags=$(grep -m1 "^${monitor:-[[:graph:]]*} tags" <<< "$file")
      if [[ -z "$tags" ]]; then
        return
      fi

      # Extract bit masks from the matching line.
      occupiedtags=$(awk '{print $3}' <<< "$tags")
      activatedtags=$(awk '{print $4}' <<< "$tags")
      focusedtags=$(awk '{print $5}' <<< "$tags")
      urgenttags=$(awk '{print $6}' <<< "$tags")

      this_tag="$component"
      mask=$((1 << this_tag))
      this_status=""

      (( occupiedtags & mask )) && this_status+='"occupied":true,' || this_status+='"occupied":false,'
      (( activatedtags & mask )) && this_status+='"activated":true,' || this_status+='"activated":false,'
      (( focusedtags & mask )) && this_status+='"focused":true,' || this_status+='"focused":false,'
      (( urgenttags & mask )) && this_status+='"urgent":true,' || this_status+='"urgent":false,'

      # Remove the trailing comma.
      this_status="${this_status%,}"
      val=$(printf '{"text":"%s",%s}' "${TAG_LABELS[this_tag]}" "$this_status")
      ;;
    layout|title|appid|mode|selmon|namedscratchpads_count|scratchpads_count|visible_appids)
      # Look for the first matching line for the component and strip off the first two fields.
      val=$(grep -m1 "^${monitor:-[[:graph:]]*} ${component}" <<< "$file" \
              | cut -d ' ' -f 3- \
              | sed 's/"/“/g')
      val=$(printf '{"text":"%s"}' "${val}")
      ;;
    *)
      val='{"text":"INVALID COMPONENT"}'
      ;;
  esac

  # Only output if the value has changed.
  if [[ "$val" != "$last_val" ]]; then
    last_val="$val"
    echo "$val"
  fi

  # Exit early if running in once mode.
  if [[ "$once_mode" == "--once" ]]; then
    exit 0
  fi
}

# Initial run
cycle

# Wait for modifications to the log file and run cycle on each change.
while inotifywait -qq -e modify "$FILE_PATH"; do
  cycle
done

