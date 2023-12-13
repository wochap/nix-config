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

# Rice completion system
# https://zsh.sourceforge.io/Doc/Release/Completion-System.html
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS} 'ma=48;5;2;38;5;16;1'

# https://github.com/Phantas0s/.dotfiles/blob/master/zsh/completion.zsh
# https://thevaluable.dev/zsh-completion-guide-examples/
# https://stackoverflow.com/questions/23152157/how-does-the-zsh-list-colors-syntax-work/23568183#23568183
# https://github.com/backdround/configuration/blob/046d9490dda15998cc2223de44e45cbcb09ef7b5/configs/terminal/zsh/zshrc#L42
zstyle ':completion:*:*' list-colors '=(#b)*(-- *)==38;5;8'
zstyle ':completion:*:functions' list-colors '=*=38;5;4'
zstyle ':completion:*:commands' list-colors '=(#b)*(-- *)==38;5;8' '=^([a-zA-Z])$='
zstyle ':completion:*:aliases' list-colors '=*=38;5;4'
zstyle ':completion:*:options' list-colors '=(#b)*(-- *)=38;5;14=38;5;8' '=^(-- *)=38;5;14'
zstyle ':completion:*:parameters' list-colors '=(#b)*(-- *)=38;5;216=38;5;8' '=^(-- *)=38;5;216'

zstyle ':completion:unambiguous' format $'%{\e[38;5;8m%}-- common substring: %{\e[38;5;2m%}%d %{\e[38;5;8m%}--%{\e[0m%}'
zstyle ':completion:*:descriptions' format $'%{\e[38;5;8m%}-- %d --%{\e[0m%}'
zstyle ':completion:*:messages' format $'%{\e[38;5;8m%}-- %d --%{\e[0m%}'
zstyle -e ':completion:*:warnings' format autocomplete:config:format:warnings
autocomplete:config:format:warnings() {
  [[ $CURRENT == 1 && -z $PREFIX$SUFFIX ]] ||
    typeset -ga reply=( $'%{\e[38;5;1m%}'"-- no matching %d completions --"$'%{\e[0m%}' )
}

# Show dotfiles by default in completion system
# _comp_options+=(globdots)

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
setopt TRANSIENT_RPROMPT

# These aliases enable us to paste example code into the terminal without the
# shell complaining about the pasted prompt symbol.
alias %= \$=

alias ~="cd ~"

