# inspiration: https://github.com/ohmyzsh/ohmyzsh/blob/master/lib/key-bindings.zsh

# http://zsh.sourceforge.net/Doc/Release/Zsh-Line-Editor.html
# http://zsh.sourceforge.net/Doc/Release/Zsh-Line-Editor.html#Zle-Builtins
# http://zsh.sourceforge.net/Doc/Release/Zsh-Line-Editor.html#Standard-Widgets
# NOTE: when ZLE widget starts with a dot (`.`), that widget will get executed in the cmd, not in the current mode/context

# ================
# Movement
# ================

# [Home] - Go to beginning of line
if [[ -n "${terminfo[khome]}" ]]; then
  for keymap in viins visual vicmd viopp menuselect; do
    bindkey -M $keymap "${terminfo[khome]}" .beginning-of-line
  done
fi

# [End] - Go to end of line
if [[ -n "${terminfo[kend]}" ]]; then
  for keymap in viins visual vicmd viopp menuselect; do
    bindkey -M $keymap "${terminfo[kend]}" .end-of-line
  done
fi

function backward-kill-blank-word() {
    local WORDCHARS='*?_-.[]~=/&;!#$%^(){}<>'
    zle backward-kill-word
    zle -f kill
}
zle -N backward-kill-blank-word
function kill-blank-word() {
    local WORDCHARS='*?_-.[]~=/&;!#$%^(){}<>'
    zle kill-word
    zle -f kill
}
zle -N kill-blank-word

# [Backspace] - delete backward char
bindkey -M menuselect '^?' backward-delete-char
# [Alt-Backspace] - delete backward word
bindkey -M viins '^[^?' backward-kill-word
# [Alt+Shift-Backspace] - delete the entire backward word
# TODO: find Alt+Shift-Backspace keycode
# HACK: kitty sends alt+shift+h instead of alt+shift+backspace
bindkey -M viins '^[^H' backward-kill-blank-word
# [Alt-Delete] - delete forward-word
bindkey -M viins '^[[3;3~' kill-word
# [Alt+Shift-Delete] - delete the entire forward word
bindkey -M viins '^[[3;4~' kill-blank-word

# [Alt-f] - move forward one word
bindkey -M viins "^[f" forward-word
# [Alt-Shift-f] - move forward one entire word
bindkey -M viins "^[F" vi-forward-blank-word
# [Alt-b] - move backward one word
bindkey -M viins "^[b" backward-word
# [Alt-Shift-b] - move backward one entire word
bindkey -M viins "^[B" vi-backward-blank-word

# [Ctrl-y] - accept option
bindkey -M menuselect '^Y' accept-line
# [Tab] - go straight to the menu and cycle there
bindkey -M viins '\t' menu-select "${terminfo[kcbt]}" menu-select
# [Shift-Tab] - insert substring occuring in all listed completions
bindkey -M viins "${terminfo[kcbt]}" insert-unambiguous-or-complete
# [Tab] [Shift-Tab] - move through the completion menu
bindkey -M menuselect '\t' menu-complete "${terminfo[kcbt]}" reverse-menu-complete

# NOTE: when selecting an option, backspace doesn't delete a char
# TODO: with the following code, backspace deletes a char
# but the option selected doesn't get highlighted
# bindkey -M emacs '\t' menu-complete "$terminfo[kcbt]" reverse-menu-complete

# [Ctrl+e] - cancel autocomplete
bindkey -M menuselect '^e' undo

# [Esc] - abort completion
bindkey -M menuselect '^?' send-break

# [LeftArrow] - move backward one char
bindkey -M menuselect "${terminfo[kcub1]}" .backward-char
# [RightArrow] - move forward one char
bindkey -M menuselect "${terminfo[kcuf1]}" .forward-char

# [Enter] - execute command in all modes
for keymap in viins visual vicmd viopp menuselect; do
  bindkey -M $keymap '\r' .accept-line
done

# Start typing + [Up-Arrow] - fuzzy find history forward
bindkey -M viins "${terminfo[kcuu1]}" history-substring-search-up
bindkey -M menuselect "${terminfo[kcuu1]}" history-substring-search-up
# Start typing + [Down-Arrow] - fuzzy find history backward
bindkey -M viins "${terminfo[kcud1]}" history-substring-search-down
bindkey -M menuselect "${terminfo[kcud1]}" history-substring-search-down

# [Alt+p] - allows you to run another command before your current command
bindkey -M viins '^[p' push-line-or-edit

# [Alt+u p] - run pro func
bindkey -M viins '^[up' pro
# [Alt+u a] - run apro func
bindkey -M viins '^[ua' apro
# [Alt+u o] - run opro func
bindkey -M viins '^[uo' opro

function .recover-line() { LBUFFER+=$ZLE_LINE_ABORTED }
zle -N .recover-line
# [Alt+g] - recover last line aborted
bindkey -M viins '^[g' .recover-line

# [Alt-V] - show the next key combo's terminal code and state what it does.
for keymap in viins visual vicmd viopp; do
  bindkey -M $keymap '^[v' describe-key-briefly
done

# [Alt-W] - type a widget name and press Enter to see the keys bound to it.
# type part of a widget name and press Enter for autocompletion.
bindkey -M viins '^[w' where-is

# [Esc] - remove key binding, use Ctrl+x
bindkey -M viins -r '^['

# [Delete] - remove key binding
bindkey -M vicmd -r '^[[3~'
