#!/usr/bin/env bash

hyprlock_pid=$(pgrep hyprlock)
if [[ -n "$hyprlock_pid" ]]; then
  exit 1
fi

# create tmp file
tmpfile=$(mktemp)

# delete tmp file on exit
trap 'rm -f "$tmpfile"' EXIT

# write config to tmp file
cat <<EOF >"$tmpfile"
  source = ~/.config/hypr/hyprlock.conf
EOF

if [ "$BACKGROUND" = "1" ]; then
  awww_image_path=$(awww query | sed 's/.*image: //')
  if ! [ -e "$awww_image_path" ]; then
    awww_image_path="$HOME/Pictures/backgrounds/lock.jpg"
  fi
  cat <<EOF >>"$tmpfile"
    background {
      path = ${awww_image_path}
      blur_passes = 0
    }
EOF
fi

# disable idle inhibidor
shell_idle_status=$(shell-idle-inhibit --status)
if [[ "$shell_idle_status" == "true" ]]; then
  shell-idle-inhibit --toggle
fi

exec hyprlock -c "$tmpfile" "$@"
