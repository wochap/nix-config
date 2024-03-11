#!/usr/bin/env bash
#
# source: https://gitee.com/guyuming76/personal/blob/dwl/gentoo/waybar-dwl/waybar-dwl.sh
# NOTE: mode required the following patch https://github.com/djpohly/dwl/wiki/modes
#
# dwl-waybar.sh - display dwl tags, layout, active mode and active window title
#   Based heavily upon this script by user "novakane" (Hugo Machet) used to do the same for yambar
#   https://codeberg.org/novakane/yambar/src/branch/master/examples/scripts/dwl-tags.sh
#
# USAGE: waybar-dwl.sh MONITOR COMPONENT
#        "COMPONENT" is an integer representing a dwl tag OR "layout" OR "title" OR "MODE"
#
# REQUIREMENTS:
#  - inotifywait ( 'inotify-tools' on arch )
#  - Launch dwl with `dwl > ~.cache/dwltags` or change $fname
#
# Now the fun part
#
### Example ~/.config/waybar/config
#
# {
#   "modules-left": ["custom/dwl_tag#0", "custom/dwl_layout", "custom/dwl_mode", "custom/dwl_title"],
#   // The empty '' argument used in the following "exec": fields works for single-monitor setups
#   // For multi-monitor setups, see https://github.com/Alexays/Waybar/wiki/Configuration
#   //     and enter the monitor id (like "eDP-1") as the first argument to waybar-dwl.sh
#   "custom/dwl_tag#0": {
#     "exec": "/path/to/waybar-dwl.sh '' 0",
#     "format": "{}",
#     "return-type": "json"
#   },
#   "custom/dwl_layout": {
#     "exec": "/path/to/waybar-dwl.sh '' layout",
#     "format": "{}",
#     "return-type": "json"
#   },
#   "custom/dwl_title": {
#     "exec": "/path/to/waybar-dwl.sh '' title",
#     "format": "{}",
#     "escape": true,
#     "return-type": "json"
#   }
#   "custom/dwl_mode": {
#     "exec": "/path/to/waybar-dwl.sh '' mode",
#     "format": "{}",
#     "escape": true,
#     "return-type": "json"
#   }
# }
#
### Example ~/.config/waybar/style.css
# #custom-dwl_layout {
#     color: #EC5800
# }
#
# #custom-dwl_title {
#     color: #017AFF
# }
#
# #custom-dwl_tag {
#     color: #875F00
# }
#
# #custom-dwl_tag.occupied {
#     color: #017AFF
# }
#
# #custom-dwl_tag.focused {
#     border-top: 1px solid #EC5800
# }
#
# #custom-dwl_tag.urgent {
#     background-color: #FF0000
# }
#

declare occupiedtags focusedtags urgenttags val last_val
declare -a tag_labels
readonly file_path="$HOME"/.cache/dwltags
tag_labels=("1" "2" "3" "4" "5" "6" "7" "8" "9")
monitor="${1}"
component="${2}"

[[ ! -f "${file_path}" ]] && printf -- '%s\n' \
  "You need to redirect dwl stdout to ~/.cache/dwltags" >&2

cycle() {
  case "${component}" in
  [012345678])
    occupiedtags=$(tac "$file_path" | grep -m1 "^${monitor:-[[:graph:]]*} tags" | awk '{print $3}')
    focusedtags=$(tac "$file_path" | grep -m1 "^${monitor:-[[:graph:]]*} tags" | awk '{print $4}')
    urgenttags=$(tac "$file_path" | grep -m1 "^${monitor:-[[:graph:]]*} tags" | awk '{print $6}')

    this_tag="${component}"
    unset this_status
    mask=$((1 << this_tag))

    if (("${occupiedtags}" & mask)) 2>/dev/null; then this_status+='"occupied",'; fi
    if (("${focusedtags}" & mask)) 2>/dev/null; then this_status+='"focused",'; fi
    if (("${urgenttags}" & mask)) 2>/dev/null; then this_status+='"urgent",'; fi

    if [[ "${this_status}" ]]; then
      this_status="${this_status%,}"
      val=$(printf -- '{"text":"%s","class":[%s]}\n' "${tag_labels[this_tag]}" "${this_status}")
    else
      val=$(printf -- '{"text":"%s","class":[]}\n' "${tag_labels[this_tag]}")
    fi
    if [ "$val" != "$last_val" ]; then
      last_val=$val
      printf -- "%s\n" "${val}"
    fi
    ;;
  layout | title | appid | mode)
    val=$(tac "$file_path" | grep -m1 "^${monitor:-[[:graph:]]*} ${component}" | cut -d ' ' -f 3- | sed s/\"/“/g)
    # if [[ $component == "layout" && $val == "[\\]" ]]; then
    #   # HACK: waybar doesn't like \\ (dwindle layout)
    #   val="[\\\]"
    # fi
    if [ "$val" != "$last_val" ]; then
      last_val=$val
      printf -- '{"text":"%s"}\n' "${val}"
    fi
    ;;
  *)
    printf -- '{"text":"INVALID INPUT"}\n'
    ;;
  esac
}

cycle
while inotifywait -qq -e modify "$file_path"; do
  cycle
done

unset -v occupiedtags focusedtags urgenttags val last_val tag_labels
