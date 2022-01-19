#!/usr/bin/env bash

function removeEmptyReceptacles {
  for win in $(bspc query -N -n .leaf.\!window); do bspc node "$win" -k; done
}

# Show scratchpad
id=$(xdo id -N kitty-scratch)
if [ -z "${id}" ]; then
  /etc/scripts/bspwm_kitty_scratch.sh &
  sleep 0.5
else
  bspc node "$id" --flag hidden=off --to-monitor focused --to-desktop focused --to-node focused --focus
fi

# Run yarn commands
kitty @ --to unix:/tmp/kitty_scratch launch --tab-title=kitty_dangerpress --type=tab --cwd ~/Projects/boc/dangerp zsh -c 'direnv allow . && eval "$(direnv export zsh)" && yarn dev & zsh'
kitty @ --to unix:/tmp/kitty_scratch launch --cwd ~/Projects/boc/dangerp zsh
kitty @ --to unix:/tmp/kitty_scratch launch --cwd ~/Projects/boc/dangerp-backend zsh -c 'direnv allow . && eval "$(direnv export zsh)" && yarn dev & zsh'
kitty @ --to unix:/tmp/kitty_scratch launch --cwd ~/Projects/boc/dangerp-backend zsh
kitty @ --to unix:/tmp/kitty_scratch goto-layout Grid


# Open projects on nvim
removeEmptyReceptacles

bspc node @2:/ -i
bspc node @3:/ -i
bspc rule -a "kitty-dangerp" -o node=@2:/
bspc rule -a "kitty-dangerp-backend" -o node=@3:/
bspc desktop -f 2

dangerp_session="$(cat << EOF
new_tab
cd ~/Projects/boc/dangerp
launch nvim
EOF
)"
echo "$dangerp_session" | kitty --class "kitty-dangerp" --session - &

dangerp_backend_session="$(cat << EOF
new_tab
cd ~/Projects/boc/dangerp-backend
launch nvim
EOF
)"
echo "$dangerp_backend_session" | kitty --class "kitty-dangerp-backend" --session - &

removeEmptyReceptacles

