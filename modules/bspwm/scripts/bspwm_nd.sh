#!/usr/bin/env bash

# Show scratchpad
id=$(xdo id -N kitty-scratch)
if [ -z "${id}" ]; then
  /etc/scripts/start-kitty-scratch.sh &
  sleep 0.5
else
  bspc node "$id" --flag hidden=off --to-monitor focused --to-desktop focused --to-node focused --focus
fi

# Run yarn commands
kitty @ --to unix:/tmp/kitty_scratch launch --tab-title=nd --type=tab --cwd ~/Projects/boc/nurse-disrupted/functions zsh -c 'yarn serve & zsh'
kitty @ --to unix:/tmp/kitty_scratch launch --cwd ~/Projects/boc/nurse-disrupted/functions zsh
kitty @ --to unix:/tmp/kitty_scratch launch --cwd ~/Projects/boc/nurse-disrupted/admin zsh -c 'yarn start & zsh'
kitty @ --to unix:/tmp/kitty_scratch launch --cwd ~/Projects/boc/nurse-disrupted/admin zsh
kitty @ --to unix:/tmp/kitty_scratch launch --cwd ~/Projects/boc/nurse-disrupted/provider zsh -c 'yarn start & zsh'
kitty @ --to unix:/tmp/kitty_scratch launch --cwd ~/Projects/boc/nurse-disrupted/provider zsh
kitty @ --to unix:/tmp/kitty_scratch launch --cwd ~/Projects/boc/nurse-disrupted/kiosk zsh -c "ssh gean@localhost -p 50922 -t 'sudo -S mount_9p hostshare && cd /Volumes/hostshare/boc/nurse-disrupted/kiosk; zsh --login' && zsh"
kitty @ --to unix:/tmp/kitty_scratch launch --cwd ~/Projects/boc/nurse-disrupted/kiosk zsh -c "ssh gean@localhost -p 50922 -t 'sudo -S mount_9p hostshare && cd /Volumes/hostshare/boc/nurse-disrupted/kiosk; zsh --login' && zsh"
kitty @ --to unix:/tmp/kitty_scratch goto-layout Grid

bspc rule -a "kitty-nd" -o desktop=^2
bspc desktop 2 -l monocle
bspc desktop -f 2

kitty_session="$(cat << EOF
new_tab nurse_disrupted
cd ~/Projects/boc/nurse-disrupted
launch nvim
EOF
)"
echo "$kitty_session" | kitty --class "kitty-nd" --session - &

