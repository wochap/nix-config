_rod_preexec () {
  eval "$(rod env)"
}

autoload -U add-zsh-hook
add-zsh-hook preexec _rod_preexec
