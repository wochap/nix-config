# cd into git repository
function pro() {
  projects=$(find ~/.config -maxdepth 1 -type d -execdir test -d {}/.git \; -print -prune)
  projects+=$(find ~/Projects -maxdepth 2 -type d -execdir test -d {}/.git \; -print -prune)
  projects+=$(find ~/ -maxdepth 1 -type d -execdir test -d {}/.git \; -print -prune)

  cd $(echo "$projects" | fzf)
}

# run npm script (requires jq)
function fns() {
  local script
  script=$(cat package.json | jq -r '.scripts | keys[] ' | sort | fzf) && npm run $(echo "$script")
}
