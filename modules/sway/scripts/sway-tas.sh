#!/usr/bin/env bash

# Show scratchpad
target="kitty-scratch"
swaymsg "[con_id=$target] move window to workspace current" &>/dev/null
swaymsg "[app_id=$target] focus" &>/dev/null

# Run yarn commands on kitty scratchpad
kitty @ --to unix:/tmp/kitty_scratch launch --tab-title=tas --type=tab --cwd ~/Projects/boc/tas-web zsh -c 'direnv allow . && export DIRENV_LOG_FORMAT="" && eval "$(direnv export zsh)" && yarn start & zsh'
kitty @ --to unix:/tmp/kitty_scratch launch --cwd ~/Projects/boc/tas-web zsh
kitty @ --to unix:/tmp/kitty_scratch goto-layout Grid

# Open projects on nvim
swaymsg assign [app_id="kitty-tas"] workspace 2
swaymsg workspace number 2
swaymsg workspace_layout tabbed

kitty_session="$(cat << EOF
new_tab tas-web
cd ~/Projects/boc/tas-web
launch nvim
EOF
)"
echo "$kitty_session" | kitty --class "kitty-tas" --session - &

