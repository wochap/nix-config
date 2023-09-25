#!/usr/bin/env bash

function killport {
  kill $(lsof -t -i:"$1") > /dev/null 2>&1
}

# TODO: Show scratchpad

# finish prev running server
killport 3000
killport 3001
sudo sh ~/Projects/boc/dangerp-backend/local-mongodb-replica/stop-mongodb-replica.sh > /dev/null 2>&1
sleep 1

# Run yarn commands on kitty scratchpad
kitty @ --to unix:/tmp/kitty_scratch launch --tab-title=dangerp-mongodb --type=tab --cwd ~/Projects/boc/dangerp-backend/local-mongodb-replica zsh -c 'sudo sh ./start-mongodb-replica.sh & zsh'
sleep 1
kitty @ --to unix:/tmp/kitty_scratch launch --cwd ~/Projects/boc/dangerp-backend/local-mongodb-replica zsh -c 'mongo --port 27018 < ./init-mongodb-replica.js & zsh'
kitty @ --to unix:/tmp/kitty_scratch launch --tab-title=dangerp --type=tab --cwd ~/Projects/boc/dangerp zsh -c 'yarn dev & zsh'
kitty @ --to unix:/tmp/kitty_scratch launch --cwd ~/Projects/boc/dangerp zsh
kitty @ --to unix:/tmp/kitty_scratch launch --cwd ~/Projects/boc/dangerp-backend zsh -c 'yarn dev & zsh'
kitty @ --to unix:/tmp/kitty_scratch launch --cwd ~/Projects/boc/dangerp-backend zsh
kitty @ --to unix:/tmp/kitty_scratch goto-layout --match title:dangerp grid

# Open projects on nvim, add nvim to tag number 2
# TODO: toggle tag 2

dangerp_session="$(
  cat <<EOF
new_tab dangerp
cd ~/Projects/boc/dangerp
launch zsh -i -c "nv; exec zsh"

new_tab dangerp-backend
cd ~/Projects/boc/dangerp-backend
launch zsh -i -c "nv; exec zsh"
EOF
)"
echo "$dangerp_session" | kitty --class "kitty-dangerp" --session - &

