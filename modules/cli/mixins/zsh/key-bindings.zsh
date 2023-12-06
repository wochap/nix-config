# source: https://github.com/ohmyzsh/ohmyzsh/blob/master/lib/key-bindings.zsh

# http://zsh.sourceforge.net/Doc/Release/Zsh-Line-Editor.html
# http://zsh.sourceforge.net/Doc/Release/Zsh-Line-Editor.html#Zle-Builtins
# http://zsh.sourceforge.net/Doc/Release/Zsh-Line-Editor.html#Standard-Widgets

# Make sure that the terminal is in application mode when zle is active, since
# only then values from $terminfo are valid
if (( ${+terminfo[smkx]} )) && (( ${+terminfo[rmkx]} )); then
  function zle-line-init() {
    echoti smkx
  }
  function zle-line-finish() {
    echoti rmkx
  }
  zle -N zle-line-init
  zle -N zle-line-finish
fi

# # NOTE: incompatible with https://github.com/marlonrichert/zsh-autocomplete
# # Start typing + [Up-Arrow] - fuzzy find history forward
# if [[ -n "${terminfo[kcuu1]}" ]]; then
#   autoload -U up-line-or-beginning-search
#   zle -N up-line-or-beginning-search
#
#   bindkey -M emacs "${terminfo[kcuu1]}" up-line-or-beginning-search
#   bindkey -M viins "${terminfo[kcuu1]}" up-line-or-beginning-search
#   bindkey -M vicmd "${terminfo[kcuu1]}" up-line-or-beginning-search
# fi
# # Start typing + [Down-Arrow] - fuzzy find history backward
# if [[ -n "${terminfo[kcud1]}" ]]; then
#   autoload -U down-line-or-beginning-search
#   zle -N down-line-or-beginning-search
#
#   bindkey -M emacs "${terminfo[kcud1]}" down-line-or-beginning-search
#   bindkey -M viins "${terminfo[kcud1]}" down-line-or-beginning-search
#   bindkey -M vicmd "${terminfo[kcud1]}" down-line-or-beginning-search
# fi

# [Home] - Go to beginning of line
if [[ -n "${terminfo[khome]}" ]]; then
  bindkey -M emacs "${terminfo[khome]}" beginning-of-line
  bindkey -M viins "${terminfo[khome]}" beginning-of-line
  bindkey -M vicmd "${terminfo[khome]}" beginning-of-line
fi
# [End] - Go to end of line
if [[ -n "${terminfo[kend]}" ]]; then
  bindkey -M emacs "${terminfo[kend]}"  end-of-line
  bindkey -M viins "${terminfo[kend]}"  end-of-line
  bindkey -M vicmd "${terminfo[kend]}"  end-of-line
fi

# [Backspace] - delete backward
bindkey -M emacs '^?' backward-delete-char
bindkey -M viins '^?' backward-delete-char
bindkey -M vicmd '^?' backward-delete-char
# [Delete] - delete forward
if [[ -n "${terminfo[kdch1]}" ]]; then
  bindkey -M emacs "${terminfo[kdch1]}" delete-char
  bindkey -M viins "${terminfo[kdch1]}" delete-char
  bindkey -M vicmd "${terminfo[kdch1]}" delete-char
else
  bindkey -M emacs "^[[3~" delete-char
  bindkey -M viins "^[[3~" delete-char
  bindkey -M vicmd "^[[3~" delete-char

  bindkey -M emacs "^[3;5~" delete-char
  bindkey -M viins "^[3;5~" delete-char
  bindkey -M vicmd "^[3;5~" delete-char
fi

# Edit the current command line in $EDITOR
autoload -U edit-command-line
zle -N edit-command-line
bindkey '\C-x\C-e' edit-command-line
