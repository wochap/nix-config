# inspiration: https://github.com/ohmyzsh/ohmyzsh/blob/master/lib/key-bindings.zsh
# http://zsh.sourceforge.net/Doc/Release/Zsh-Line-Editor.html
# http://zsh.sourceforge.net/Doc/Release/Zsh-Line-Editor.html#Zle-Builtins
# http://zsh.sourceforge.net/Doc/Release/Zsh-Line-Editor.html#Standard-Widgets

function multibindkey() {
  # Convert the space-separated string to an array
  local keymaps=("${(s: :)1}")
  for keymap in "${keymaps[@]}"; do
    bindkey -M $keymap "${@:2}"
  done
}

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

function .recover-line() { LBUFFER+=$ZLE_LINE_ABORTED }
zle -N .recover-line

# ================
# Clean up
# ================
# zsh-vi-mode adds key bindings that I don't want
# so reset those to its default

# [Shift+Delete] - HACK: stop printing `~`
bindkey -M viins '^[[3;2~' delete-char

# [Backspace] - delete backward char
bindkey -M menuselect '^?' .backward-delete-char

# [UpArrow] - go 1 line up
multibindkey 'visual vicmd viopp' "${terminfo[kcuu1]}" .up-line

# [DownArrow] - go 1 line down
multibindkey 'visual vicmd viopp' "${terminfo[kcud1]}" .down-line

# [Esc] - remove key binding to espace to vicmd, use Ctrl+x
bindkey -M viins -r '^['

# [Ctrl+l] - remove key binding
bindkey -M viins -r '^L'

# [Ctrl+c] -
multibindkey 'viins visual vicmd viopp menuselect' '^C' send-break

# ================
# Movement
# ================
# NOTE: when ZLE widget starts with a dot (`.`), that widget will get executed in the cmd, not in the current mode/context

# [Home] - always go to beginning of line
multibindkey 'viins visual vicmd viopp menuselect' "${terminfo[khome]}" .beginning-of-line

# [End] - always go to end of line
multibindkey 'viins visual vicmd viopp menuselect' "${terminfo[kend]}" .end-of-line

# [Alt+RightArrow] - move forward one word
multibindkey 'viins menuselect' "^[[1;3C" .vi-forward-word

# [Alt+Shift+RightArrow] - move forward one entire word
multibindkey 'viins menuselect' "^[[1;4C" .vi-forward-blank-word

# [Alt+LeftArrow] - move backward one word
multibindkey 'viins menuselect' "^[[1;3D" .vi-backward-word

# [Alt+Shift+LeftArrow] - move backward one entire word
multibindkey 'viins menuselect' "^[[1;4D" .vi-backward-blank-word

# [Alt+e] - like `e` in normal mode
bindkey -M viins "^[e" .vi-forward-word-end

# [Alt+Shift+e] - like `E` in normal mode
bindkey -M viins "^[E" .vi-forward-blank-word-end

# ================
# Modification
# ================

# [Alt+Backspace] - delete backward word
bindkey -M viins '^[^?' backward-kill-word

# [Alt+Shift+Backspace] - delete the entire backward word
bindkey -M viins '^[^H' backward-kill-blank-word
# TODO: find Alt+Shift-Backspace keycode
# HACK: kitty sends alt+shift+h instead of alt+shift+backspace

# [Alt+Delete] - delete forward-word
bindkey -M viins '^[[3;3~' kill-word

# [Alt+Shift+Delete] - delete the entire forward word
bindkey -M viins '^[[3;4~' kill-blank-word

# ================
# Completion menu
# ================

# [Ctrl+y] - accept and exit selected option
bindkey -M menuselect '^Y' accept-line

# [Ctrl+e] - undo and exit completion menu
bindkey -M menuselect '^e' undo

# [Esc] - abort completion
bindkey -M menuselect '^[' send-break

# [Tab] [Shift+Tab] - go straight to the menu and cycle there
bindkey -M viins '\t' menu-select "${terminfo[kcbt]}" menu-select

# [Tab] [Shift+Tab] - move through the completion menu
bindkey -M menuselect '\t' menu-complete "${terminfo[kcbt]}" reverse-menu-complete

# [LeftArrow] - move backward one char
bindkey -M menuselect "${terminfo[kcub1]}" .backward-char

# [RightArrow] - move forward one char
bindkey -M menuselect "${terminfo[kcuf1]}" .forward-char

# [Enter] - execute command in all modes
multibindkey 'viins visual vicmd viopp menuselect' '\r' .accept-line

# TODO: add [Shift+Enter] to do Ctrl+v-Ctrl+j to insert new line

# ================
# Plugins
# ================

# [Alt+UpArrow] - unbind dirhistory
bindkey -M viins -r '^[[1;3A'

# [Alt+DownArrow] - unbind dirhistory
bindkey -M viins -r '^[[1;3B'

# Start typing + [Up-Arrow] - fuzzy find history forward
multibindkey 'viins menuselect' "${terminfo[kcuu1]}" history-substring-search-up

# Start typing + [Down-Arrow] - fuzzy find history backward
multibindkey 'viins menuselect' "${terminfo[kcud1]}" history-substring-search-down

# ================
# Misc
# ================

# [Ctrl+y] - copy buffer
bindkey -M viins '^y' copybuffer

# [Alt+p] - allows you to run another command before your current command
bindkey -M viins '^[p' push-line-or-edit

# [Alt+g] - recover last line aborted
bindkey -M viins '^[g' .recover-line

# [Alt+u p] - run pro func
bindkey -M viins '^[up' pro

# [Alt+u a] - run apro func
bindkey -M viins '^[ua' apro

# [Alt+u o] - run opro func
bindkey -M viins '^[uo' opro

# [Alt+v] - show the next key combo's terminal code and state what it does.
multibindkey 'viins visual vicmd viopp menuselect' '^[v' describe-key-briefly

# [Alt+w] - type a widget name and press Enter to see the keys bound to it.
# type part of a widget name and press Enter for autocompletion.
bindkey -M viins '^[w' where-is

