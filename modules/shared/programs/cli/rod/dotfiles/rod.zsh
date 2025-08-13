# HACK: NO_ROD is the only workaround that works
# If you are performing automation, make sure to disable ROD
# by using the NO_ROD environment variable
_rod_preexec () {
  # Skip rod if NO_ROD is set
  [[ -n "$NO_ROD" ]] && return 0

  # Skip rod if we're in a tmux send-keys context
  # When tmux sends keys, it doesn't set certain terminal variables
  [[ -z "$TTY" ]] && return 0

  # Alternative: Check if this is an interactive shell
  [[ ! -o interactive ]] && return 0

  # Skip if stdin is not a terminal (tmux send-keys doesn't provide a tty)
  [[ ! -t 0 ]] && return 0

  # Run rod, redirecting its input from the terminal device, and evaluate its output
  eval $(rod env --no-export)
}

autoload -U add-zsh-hook
add-zsh-hook preexec _rod_preexec
