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

declare occupiedtags activatedtags focusedtags urgenttags val last_val
declare -a tag_labels
readonly file_path="$HOME"/.cache/dwl/logs
tag_labels=("1" "2" "3" "4" "5" "6" "7" "8" "9")
monitor="${1}"
component="${2}"
once_mode="${3}"

[[ ! -f "${file_path}" ]] && printf -- '%s\n' \
  "You need to redirect dwl stdout to $file_path" >&2

cycle() {
  file=$(tac "$file_path")
  case "${component}" in
  [012345678])
    tags=$(echo "$file" | grep -m1 "^${monitor:-[[:graph:]]*} tags")
    occupiedtags=$(echo "$tags" | awk '{print $3}')
    activatedtags=$(echo "$tags" | awk '{print $4}')
    focusedtags=$(echo "$tags" | awk '{print $5}')
    urgenttags=$(echo "$tags" | awk '{print $6}')

    this_tag="${component}"
    unset this_status
    mask=$((1 << this_tag))

    if (("${occupiedtags}" & mask)) 2>/dev/null; then this_status+='"occupied":true,'; else this_status+='"occupied":false,'; fi
    if (("${activatedtags}" & mask)) 2>/dev/null; then this_status+='"activated":true,'; else this_status+='"activated":false,'; fi
    if (("${focusedtags}" & mask)) 2>/dev/null; then this_status+='"focused":true,'; else this_status+='"focused":false,'; fi
    if (("${urgenttags}" & mask)) 2>/dev/null; then this_status+='"urgent":true,'; else this_status+='"urgent":false,'; fi

    this_status="${this_status%,}"
    val=$(printf -- '{"text":"%s",%s}\n' "${tag_labels[this_tag]}" "${this_status}")

    if [ "$val" != "$last_val" ]; then
      last_val=$val
      printf -- "%s\n" "${val}"
    fi
    ;;
  layout | title | appid | mode | selmon | namedscratchpads_count | scratchpads_count | visible_appids)
    val=$(echo "$file" | grep -m1 "^${monitor:-[[:graph:]]*} ${component}" | cut -d ' ' -f 3- | sed s/\"/“/g)

    if [ "$val" != "$last_val" ]; then
      last_val=$val
      printf -- '{"text":"%s"}\n' "${val}"
    fi
    ;;
  *)
    printf -- '{"text":"INVALID COMPONENT"}\n'
    ;;
  esac
}

cycle

if [ "$once_mode" == "--once" ]; then
  exit 0
fi

while inotifywait -qq -e modify "$file_path"; do
  cycle
done

unset -v occupiedtags activatedtags focusedtags urgenttags val last_val tag_labels
