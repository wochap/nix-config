#!/usr/bin/env bash

function killport {
  kill $(lsof -t -i:"$1")
}

# Show scratchpad
sway-focus-toggle --only-focus kitty-scratch $HOME/.config/kitty/scripts/kitty-scratch.sh
sleep 0.5

# finish prev running server
killport 3001

# Run yarn commands on kitty scratchpad
kitty @ --to unix:/tmp/kitty_scratch launch --tab-title=dangerp --type=tab --cwd ~/Projects/boc/dangerp zsh -c 'yarn dev & zsh'
kitty @ --to unix:/tmp/kitty_scratch launch --cwd ~/Projects/boc/dangerp zsh
kitty @ --to unix:/tmp/kitty_scratch launch --cwd ~/Projects/boc/dangerp-backend zsh -c 'yarn dev & zsh'
kitty @ --to unix:/tmp/kitty_scratch launch --cwd ~/Projects/boc/dangerp-backend zsh
kitty @ --to unix:/tmp/kitty_scratch goto-layout --match title:dangerp grid

# Open projects on nvim
swaymsg assign [app_id="kitty-dangerp"] workspace 2
swaymsg workspace number 2
# swaymsg workspace_layout tabbed
swaymsg -- '[workspace="2" tiling] layout tabbed'

dangerp_session="$(
  cat <<EOF
new_tab dangerp
cd ~/Projects/boc/dangerp
launch nvim

new_tab dangerp-backend
cd ~/Projects/boc/dangerp-backend
launch nvim
EOF
)"
echo "$dangerp_session" | kitty --class "kitty-dangerp" --session - &
