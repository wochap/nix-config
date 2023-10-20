# Highlighting --help messages with bat
alias bathelp='bat --plain --language=help'
help() {
  "$@" --help 2>&1 | bathelp
}

# HACK: Fix slowness of pastes with zsh-syntax-highlighting.zsh
# https://github.com/zsh-users/zsh-autosuggestions/issues/238
pasteinit() {
  OLD_SELF_INSERT=${${(s.:.)widgets[self-insert]}[2,3]}
  zle -N self-insert url-quote-magic # I wonder if you'd need `.url-quote-magic`?
}
pastefinish() {
  zle -N self-insert $OLD_SELF_INSERT
}
zstyle :bracketed-paste-magic paste-init pasteinit
zstyle :bracketed-paste-magic paste-finish pastefinish

# Clear right promt
RPROMPT=""

# Completion for kitty
kitty + complete setup zsh | source /dev/stdin

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

