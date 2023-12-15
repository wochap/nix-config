# ================
# History
# ================

# Remove superfluous blanks being added to history.
setopt HIST_REDUCE_BLANKS

# Don't display duplicates when searching the history with Ctrl+R.
setopt HIST_FIND_NO_DUPS

# Don't enter _any_ repeating commands into the history.
setopt HIST_IGNORE_ALL_DUPS

# Ignore duplicates when writing history file.
setopt HIST_SAVE_NO_DUPS

# Sessions append to the history list in the order they exit.
setopt APPEND_HISTORY

# ================
# Completion menu
# ================

# Completion for kitty
# kitty + complete setup zsh | source /dev/stdin

# Zsh completion has this dumb thing where it will SSH into remote servers
# to suggest file paths. With autosuggestions, this causes an SSH
# connection to occur for each keypress causing a number of undesirable
# effects:
# - Overloading the remote server and causing you to get timed out
# - Mangling the prompt, if a TUI password request gets rendered
# - Repeatedly popping up an SSH passphrase prompt and forcing you to lose
# focus on your terminal if a GUI askpass is setup
#
# All of this is dumb, and honestly a terrible idea. Disable remote-access
# to fix
zstyle ':completion:*' remote-access no

# ================
# Misc
# ================

# Don't treat non-executable files in your $path as commands. This makes sure
# they don't show up as command completions. Settinig this option can impact
# performance on older systems, but should not be a problem on modern ones.
# source: https://github.com/marlonrichert/zsh-launchpad/blob/main/.config/zsh/rc.d/07-opts.zsh
setopt HASH_EXECUTABLES_ONLY

# Treat comments pasted into the command line as comments, not code.
setopt INTERACTIVE_COMMENTS

# Sort numbers numerically, not lexicographically.
setopt NUMERIC_GLOB_SORT

# Auto-remove the right side of each prompt when you press enter. This way,
# we'll have less clutter on screen. This also makes it easier to copy code from
# our terminal.
# setopt TRANSIENT_RPROMPT

# ================
# Aliases
# ================

# These aliases enable us to paste example code into the terminal without the
# shell complaining about the pasted prompt symbol.
alias %= \$=

alias ~="cd ~"

# Prevent nested nvim in nvim terminal
if [ -n "$NVIM" ]; then
  alias nvim='nvr -l --remote-wait-silent "$@"'
  alias nv='nvr -l --remote-wait-silent "$@"'
fi
if [ -n "$NVIM" ]; then
  export VISUAL="nvr -l --remote-wait-silent"
  export EDITOR="nvr -l --remote-wait-silent"
else
  export VISUAL="nvim"
  export EDITOR="nvim"
fi

