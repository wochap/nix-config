#!/usr/bin/env bash

function killport {
  kill $(lsof -t -i:"$1") >/dev/null 2>&1
}

# Finish prev running server
killport 3030
killport 5000

# Focus DWL tag 2
ydotool key 125:1 3:1 3:0 125:0

# Open projects on nvim
session="$(
  cat <<EOF
new_tab todofull-frontend-3
cd ~/Projects/vtm/todofull_frontend_3
launch zsh -c 'nvim && zsh'
launch zsh -c 'pnpm dev'

new_tab todo-mujeron
cd ~/Projects/vtm/todo-mujeron
launch zsh -c 'nvim && zsh'
launch zsh -c 'pnpm local'
cd ~/Projects/vtm/vtm-flakes
launch zsh -c 'docker-compose up'
EOF
)"
echo "$session" | kitty --class "kitty-vtm" --session - &
