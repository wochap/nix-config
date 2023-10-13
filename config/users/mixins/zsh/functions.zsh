# cd into git repository
function pro() {
  projects=$(find ~/.config -maxdepth 1 -type d -execdir test -d {}/.git \; -print -prune)
  projects+="\n"
  projects+=$(find ~/Projects -maxdepth 2 -type d -execdir test -d {}/.git \; -print -prune)
  projects+="\n"
  projects+=$(find ~/ -maxdepth 1 -type d -execdir test -d {}/.git \; -print -prune)

  selected=$(echo "$projects" | fzf)

  if [[ -n "$selected" ]]; then
    cd $selected
  fi
}

function killport {
  kill $(lsof -t -i:"$1") > /dev/null 2>&1
}

function opro() {
  projects=$(find /etc/scripts/projects -type l,f -name "*.sh")

  $(echo "$projects" | fzf)
}

function scripts() {
  scripts=$(find /etc/scripts -type l,f -name "*.sh")

  $(echo "$scripts" | fzf)
}

# run npm script (requires jq)
function fns() {
  local script
  script=$(cat package.json | jq -r '.scripts | keys[] ' | sort | fzf) && npm run $(echo "$script")
}

# HACK: remove padding inside kitty
function run-without-kpadding() {
  if [[ -n $KITTY_PID ]]; then
    kitty @ set-spacing padding=0
    "$@"
    kitty @ set-spacing padding=7
  else
    "$@"
  fi
}
