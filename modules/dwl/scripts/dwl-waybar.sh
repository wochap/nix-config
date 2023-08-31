#!/usr/bin/env bash
#
# dwl-waybar.sh - display dwl layout and active title
#   Based heavily upon this script by user "novakane" (Hugo Machet) used to do the same for yambar
#   https://codeberg.org/novakane/yambar/src/branch/master/examples/scripts/dwl-tags.sh
#
# USAGE: waybar-dwl.sh MONITOR COMPONENT
#        "COMPONENT" is a string "layout" OR "title"
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
#   "modules-left": ["custom/dwl_layout", "custom/dwl_title"],
#   // The empty '' argument used in the following "exec": fields works for single-monitor setups
#   // For multi-monitor setups, see https://github.com/Alexays/Waybar/wiki/Configuration
#   //     and enter the monitor id (like "eDP-1") as the first argument to waybar-dwl.sh
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

# Variables
declare output title layout
readonly fname="$HOME"/.cache/dwltags
# TODO: what if there are multiple DWL instance which share the the file name, will is cause problem? and this file will increese constantly, how to trim it?

monitor="${1}"
component="${2}"

_cycle() {
  case "${component}" in
  layout)
    printf -- '{"text":"%s"}\n' "${layout}"
    ;;
  title)
    printf -- '{"text":"%s"}\n' "${title}"
    ;;
  *)
    printf -- '{"text":"INVALID INPUT"}\n'
    ;;
  esac
}

while [[ -n "$(pgrep waybar)" ]]; do

  [[ ! -f "${fname}" ]] && printf -- '%s\n' \
    "You need to redirect dwl stdout to ~/.cache/dwltags" >&2

  # Get info from the file
  output="$(grep "${monitor}" "${fname}" | tail -n7)"
  title="$(echo "${output}" | grep '^[[:graph:]]* title' | cut -d ' ' -f 3- | sed s/\"/“/g)" # Replace quotes - prevent waybar crash
  layout="$(echo "${output}" | grep '^[[:graph:]]* layout' | cut -d ' ' -f 3-)"

  if [[ $layout == "[\\]" ]]; then
    # HACK: waybar doesn't like \\
    layout="[\\\]"
  fi

  _cycle

  # 60-second timeout keeps this from becoming a zombified process when waybar is no longer running
  inotifywait -t 60 -qq --event modify "${fname}"
done

unset -v layout output title
