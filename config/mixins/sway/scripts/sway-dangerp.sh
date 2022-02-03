#!/usr/bin/env bash

function killport {
  kill $(lsof -t -i:"$1")
}

# Show scratchpad
target="kitty-scratch"
swaymsg "[con_id=$target] move window to workspace current" &>/dev/null
swaymsg "[app_id=$target] focus" &>/dev/null

# finish prev running server
killport 3001

# Run yarn commands on kitty scratchpad
kitty @ --to unix:/tmp/kitty_scratch launch --tab-title=dangerp --type=tab --cwd ~/Projects/boc/dangerp zsh -c 'direnv allow . && export DIRENV_LOG_FORMAT="" && eval "$(direnv export zsh)" && yarn dev & zsh'
kitty @ --to unix:/tmp/kitty_scratch launch --cwd ~/Projects/boc/dangerp zsh
kitty @ --to unix:/tmp/kitty_scratch launch --cwd ~/Projects/boc/dangerp-backend zsh -c 'direnv allow . && export DIRENV_LOG_FORMAT="" && eval "$(direnv export zsh)" && yarn dev & zsh'
kitty @ --to unix:/tmp/kitty_scratch launch --cwd ~/Projects/boc/dangerp-backend zsh
kitty @ --to unix:/tmp/kitty_scratch goto-layout Grid

# Open projects on nvim
swaymsg assign [app_id="kitty-dangerp"] workspace 2
swaymsg workspace number 2
swaymsg workspace_layout tabbed

dangerp_session="$(cat << EOF
new_tab dangerp
cd ~/Projects/boc/dangerp
launch nvim

new_tab dangerp-backend
cd ~/Projects/boc/dangerp-backend
launch nvim
EOF
)"
echo "$dangerp_session" | kitty --class "kitty-dangerp" --session - &

