# inspiration: https://github.com/ohmyzsh/ohmyzsh/blob/master/lib/key-bindings.zsh
# http://zsh.sourceforge.net/Doc/Release/Zsh-Line-Editor.html
# http://zsh.sourceforge.net/Doc/Release/Zsh-Line-Editor.html#Zle-Builtins
# http://zsh.sourceforge.net/Doc/Release/Zsh-Line-Editor.html#Standard-Widgets

# NOTE: with powerlevel10k
local key_up="^[OA"
local key_down="^[OB"
local key_left="^[OD"
local key_right="^[OC"
local key_home="^[OH"
local key_end="^[OF"

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

custom-forward-char() {
  local cursor_position=${CURSOR}
  local command_line=${BUFFER}
  local line_length=${#command_line}

  zle .forward-char
  if [[ $cursor_position -eq $line_length ]]; then
    zle autosuggest-accept
  fi
}
zle -N custom-forward-char

custom-autosuggest-accept-or-expand-or-complete-prefix() {
  local suggestion=${POSTDISPLAY}
  local -P word=$IPREFIX$PREFIX$SUFFIX$ISUFFIX
  if [[ -n "$suggestion" ]]; then
    zle autosuggest-accept
  else
    zle expand-or-complete-prefix
  fi
}
zle -N custom-autosuggest-accept-or-expand-or-complete-prefix

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
multibindkey 'visual vicmd viopp' "$key_up" .up-line

# [DownArrow] - go 1 line down
multibindkey 'visual vicmd viopp' "$key_down" .down-line

# [LeftArrow] - go left 1 char
multibindkey 'visual vicmd viopp' "$key_left" .backward-char

# [RightArrow] - go right 1 char
multibindkey 'visual vicmd viopp' "$key_right" .forward-char

# [Esc] - remove key binding to espace to vicmd, use Ctrl+x
# bindkey -M viins -r '^['

# [Ctrl+l] - remove key binding
bindkey -M viins -r '^L'

# [Ctrl+c] -
multibindkey 'viins menuselect' '^C' send-break

# [Ctrl+c] TODO: dont send break when in vicmd mode
# multibindkey 'visual vicmd viopp' '^C' .down-line

# ================
# Movement
# ================
# NOTE: when ZLE widget starts with a dot (`.`), that widget will get executed in the cmd, not in the current mode/context

# [Home] - always go to beginning of line
multibindkey 'viins visual vicmd viopp menuselect' "$key_home" .beginning-of-line

# [End] - always go to end of line
multibindkey 'viins visual vicmd viopp menuselect' "$key_end" .end-of-line

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
bindkey -M menuselect "$key_left" .backward-char

# [RightArrow] - move forward one char
# bindkey -M menuselect "$key_right" .forward-char

# [Enter] - execute command in all modes
multibindkey 'viins visual vicmd viopp menuselect' '\r' .accept-line

# [Ctrl+\] - search in the completion menu
# press again to clear and search again
bindkey -M viins '^\' menu-search

# [Backspace] - Exit menu-search
bindkey -M menuselect '^?' undo

# [Ctrl+Space] - expand or complete prefix if there isn't a suggestion
multibindkey 'viins menuselect' '^ ' custom-autosuggest-accept-or-expand-or-complete-prefix

# ================
# Plugins
# ================

# [RightArrow] - move forward one char and if at the end of line accept suggestion
multibindkey 'viins menuselect' "$key_right" custom-forward-char

# [Ctrl+Space] - accept suggestion if there is any
multibindkey 'viins menuselect' '^ ' custom-autosuggest-accept-or-expand-or-complete-prefix

# [Alt+RightArrow] - dirhistory future
bindkey -M vicmd "^[[1;3C" dirhistory_zle_dirhistory_future

# [Alt+LeftArrow] - dirhistory back
bindkey -M vicmd "^[[1;3D" dirhistory_zle_dirhistory_back

# [Alt+UpArrow] - dirhistory up
bindkey -M vicmd '^[[1;3A' dirhistory_zle_dirhistory_up

# [Alt+DownArrow] - dirhistory down
bindkey -M vicmd '^[[1;3B' dirhistory_zle_dirhistory_down

# Start typing + [Up-Arrow] - fuzzy find history forward
multibindkey 'viins menuselect' "$key_up" history-substring-search-up

# Start typing + [Down-Arrow] - fuzzy find history backward
multibindkey 'viins menuselect' "$key_down" history-substring-search-down

# ================
# Misc
# ================

# TODO: add [Shift+Enter] to do Ctrl+v-Ctrl+j to insert new line

# [Ctrl+k] - clear screen
bindkey -M viins '^k' clear-screen

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

# [Ctrl+k] - clear terminal
multibindkey 'viins visual vicmd viopp menuselect' '^K' clear-screen

