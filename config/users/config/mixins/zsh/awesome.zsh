
function pro() {
  projects=$(find ~/Projects -maxdepth 2 -type d -execdir test -d {}/.git \; -print -prune)
  projects+=$(find ~/ -maxdepth 1 -type d -execdir test -d {}/.git \; -print -prune)

  cd $(echo "$projects" | fzf)
}

