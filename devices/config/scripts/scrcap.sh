#!/usr/bin/env cached-nix-shell
#! nix-shell -i bash -p maim slop

# A script that takes a screenshot (prompts you for what region/window to
# capture) and stores it in the clipboard.

tmp=$(mktemp)
trap "rm -f '$tmp'" EXIT

# Delay for long enough that we can refocus the targeted window
if maim --delay=${2:-1} -us >"$tmp"; then
  xclip -selection clipboard -t image/png "$tmp" &&
    notify-desktop "Screenshot saved" "Copied image to clipboard"
else
  notify-desktop -u low "Aborted screenshot"
fi
