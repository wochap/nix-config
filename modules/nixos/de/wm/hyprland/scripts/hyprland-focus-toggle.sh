#!/usr/bin/env bash
# https://gitlab.com/wef/dotfiles/-/blob/master/bin/sway-focus

PROG=$(basename $0)
TEMP=$(getopt --options sth --longoptions only-focus,help -- "$@") || exit 1
eval set -- "$TEMP"
only_focus=""

for i in "$@"; do
  case "$i" in
  -h | --help)
    exit 0
    ;;
  --only-focus)
    only_focus="set"
    shift
    ;;
  esac
done

shift
target="$1"
runstring="$2"
echo "$PROG: target='$target' runstring='$runstring'" >&2

current_workspace="$(hyprctl monitors -j | jq '.[] | select(.focused==true)' | jq -j '.activeWorkspace.name')"

[ -z "$current_workspace" ] && {
  notify-send "Scratchpad" "Some Error Occured while getting current workspace."
  exit 1
}
program_data=$(hyprctl clients -j | jq ".[] | select(.class == \"$target\")")
if [[ "$program_data" ]]; then
  pinned=$(echo "$program_data" | jq ".pinned" | head -n 1)
  pid=$(echo "$program_data" | jq ".pid" | head -n 1)
  inSpecialWs=$(echo "$program_data" | jq '. | select(.workspace.name == "special") |= . + {inSpecialWs: true} | select(.workspace.name != "special") |= . + {inSpecialWs: false} | .inSpecialWs' | head -n 1)
  visible=$(! $inSpecialWs && echo true || echo false)
  if [[ "$visible" == "false" ]]; then
    hyprctl dispatch movetoworkspace "$current_workspace,pid:$pid" &>/dev/null
    hyprctl dispatch focuswindow "pid:$pid" &>/dev/null

    if [[ "$pinned" == "false" ]]; then
      hyprctl dispatch pin "pid:$pid" &>/dev/null
    fi
  else
    if ! [[ "$only_focus" ]]; then
      # HACK: if window is pinned, it can't be moved to special workspace
      if [[ "$pinned" == "true" ]]; then
        hyprctl dispatch pin "pid:$pid" &>/dev/null
      fi
      hyprctl dispatch movetoworkspacesilent "special,pid:$pid" &>/dev/null
    fi
  fi
else
  if [[ "$runstring" ]]; then
    hyprctl dispatch exec "$runstring"
  fi
fi
