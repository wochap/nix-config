# inspiration: https://github.com/ohmyzsh/ohmyzsh/blob/master/lib/key-bindings.zsh

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

# Use emacs key bindings
bindkey -e

# [Home] - Go to beginning of line
if [[ -n "${terminfo[khome]}" ]]; then
  bindkey -M emacs "${terminfo[khome]}" beginning-of-line
fi
# [End] - Go to end of line
if [[ -n "${terminfo[kend]}" ]]; then
  bindkey -M emacs "${terminfo[kend]}"  end-of-line
fi

# [Backspace] - delete backward
bindkey -M emacs '^?' backward-delete-char
# [Delete] - delete forward
if [[ -n "${terminfo[kdch1]}" ]]; then
  bindkey -M emacs "${terminfo[kdch1]}" delete-char
else
  bindkey -M emacs "^[[3~" delete-char
  bindkey -M emacs "^[3;5~" delete-char
fi

# [Alt-Delete] - delete whole forward-word
bindkey -M emacs '^[[3;3~' kill-word
# [Alt-RightArrow] - move forward one word
bindkey -M emacs '^[[1;3C' forward-word
# [Alt-LeftArrow] - move backward one word
bindkey -M emacs '^[[1;3D' backward-word

# Edit the current command line in $EDITOR
autoload -U edit-command-line
zle -N edit-command-line
bindkey '\C-x\C-e' edit-command-line

# [Tab] - go straight to the menu and cycle there
bindkey -M emacs '\t' menu-select "${terminfo[kcbt]}" menu-select
# [Shift-Tab] - move through the completion menu backwards
bindkey -M menuselect '\t' menu-complete "${terminfo[kcbt]}" reverse-menu-complete

# NOTE: when selecting an option, backspace doesn't delete a char
# TODO: with the following code, backspace deletes a char
# but the option selected doesn't get highlighted
# bindkey -M emacs '\t' menu-complete "$terminfo[kcbt]" reverse-menu-complete

# [Ctrl+e] - cancel autocomplete
bindkey -M emacs '^e' send-break

# [LeftArrow] - move backward one char
bindkey -M menuselect "${terminfo[kcub1]}" .backward-char
# [RightArrow] - move forward one char
bindkey -M menuselect "${terminfo[kcuf1]}" .forward-char

# [Enter] - execute the command in menuselect mode
bindkey -M menuselect '\r' .accept-line

# Start typing + [Up-Arrow] - fuzzy find history forward
bindkey -M emacs "${terminfo[kcuu1]}" history-substring-search-up
bindkey -M menuselect "${terminfo[kcuu1]}" history-substring-search-up
# Start typing + [Down-Arrow] - fuzzy find history backward
bindkey -M emacs "${terminfo[kcud1]}" history-substring-search-down
bindkey -M menuselect "${terminfo[kcud1]}" history-substring-search-down

# [Alt+UpArrow] remove key binding
bindkey -r "^[[1;3A" -M emacs
