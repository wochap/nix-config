#!/usr/bin/env bash
# Show or hide the webscoop browser window on Hyprland (0.56, Lua dispatchers).
# Called from webscoop hooks, which provide WEBSCOOP_BROWSER_PID.

pid=${WEBSCOOP_BROWSER_PID:-}
[ -n "$pid" ] || exit 0

case "${1:-}" in
show)
  ws=$(hyprctl activeworkspace -j | jq -r .id)
  hyprctl dispatch "hl.dsp.window.move({ workspace = \"$ws\", follow = false, window = \"pid:$pid\" })"
  hyprctl dispatch "hl.dsp.focus({ window = \"pid:$pid\" })"
  ;;
hide)
  hyprctl dispatch "hl.dsp.window.move({ workspace = \"special:webscoop\", follow = false, window = \"pid:$pid\" })"
  ;;
*)
  echo "usage: webscoop-window show|hide" >&2
  exit 2
  ;;
esac
