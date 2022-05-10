#!/usr/bin/env bash

function removeEmptyReceptacles {
  for win in $(bspc query -N -n .leaf.\!window); do bspc node "$win" -k; done
}

# Show scratchpad
id=$(xdo id -N kitty-scratch)
if [ -z "${id}" ]; then
  /etc/scripts/start-kitty-scratch.sh &
  sleep 0.5
else
  bspc node "$id" --flag hidden=off --to-monitor focused --to-desktop focused --to-node focused --focus
fi

# Run yarn commands
kitty @ --to unix:/tmp/kitty_scratch launch --tab-title=tas --type=tab --cwd ~/Projects/boc/tas-web zsh -c 'direnv allow . && export DIRENV_LOG_FORMAT="" && eval "$(direnv export zsh)" && yarn start & zsh'
kitty @ --to unix:/tmp/kitty_scratch launch --cwd ~/Projects/boc/tas-web zsh
kitty @ --to unix:/tmp/kitty_scratch goto-layout Grid

# Open projects on nvim
removeEmptyReceptacles

bspc node @2:/ -i
bspc rule -a "kitty-tas" -o node=@2:/
bspc desktop 2 -l monocle
bspc desktop -f 2

dangerp_session="$(cat << EOF
new_tab tas
cd ~/Projects/boc/tas-web
launch nvim
EOF
)"
echo "$dangerp_session" | kitty --class "kitty-tas" --session - &

removeEmptyReceptacles

