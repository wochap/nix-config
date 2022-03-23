# Ctrl + left/right arrow
# bindkey "^[[1;5C" forward-word
# bindkey "^[[1;5D" backward-word

# ENABLE ZSH COMPLETION SYSTEM (OMZSH USED TO DO IT FOR US)
# zmodload -i zsh/complist
# autoload -U bashcompinit
# bashcompinit

# Allow shift-tab in ZSH suggestions
# bindkey '^[[Z' reverse-menu-complete

# highlight selection
# zstyle ':completion:*' menu select

# case-insensitive completion
# zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# Allow changing directories without `cd`.
# setopt AUTOCD

### Fix slowness of pastes with zsh-syntax-highlighting.zsh
### https://github.com/zsh-users/zsh-autosuggestions/issues/238
pasteinit() {
  OLD_SELF_INSERT=${${(s.:.)widgets[self-insert]}[2,3]}
  zle -N self-insert url-quote-magic # I wonder if you'd need `.url-quote-magic`?
}

pastefinish() {
  zle -N self-insert $OLD_SELF_INSERT
}
zstyle :bracketed-paste-magic paste-init pasteinit
zstyle :bracketed-paste-magic paste-finish pastefinish
### Fix slowness of pastes

# Clear right promt
RPROMPT=""

# Completion for kitty
kitty + complete setup zsh | source /dev/stdin

# Setup lorri/direnv
export DIRENV_LOG_FORMAT=
eval "$(direnv hook zsh)"

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

# ZSH_WEB_SEARCH_ENGINES=(
#   nixos "https://search.nixos.org/options?channel=unstable&from=0&size=50&sort=relevance&type=packages&query="
#   nix "https://search.nixos.org/packages?channel=unstable&from=0&size=50&sort=relevance&type=packages&query="
# )
ZSH_WEB_SEARCH_ENGINES=(reddit "https://www.reddit.com/search/?q=")

# Prevent nested nvim in nvim terminal
if [[ -n "$NVIM_LISTEN_ADDRESS" ]]
then
  if [[ -x "$(command -v nvr)" ]]
  then
    alias nvim=nvr
  else
    alias nvim='echo "No nesting!"'
  fi
fi

