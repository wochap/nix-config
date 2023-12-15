# ================
# Plugins
# ================

## powerlevel10k

# To customize prompt, run `p10k configure` or edit ~/.config/zsh/.p10k.zsh.
[[ ! -f ~/.config/zsh/.p10k.zsh ]] || source ~/.config/zsh/.p10k.zsh

zinit ice lucid \
  depth=1 src="powerlevel10k.zsh-theme"
zinit light romkatv/powerlevel10k

## zsh-autocomplete

# Show dotfiles in complete menu
setopt GLOB_DOTS

# Disable zsh-autocomplete key bindings
zstyle ':autocomplete:key-bindings' enabled no

# Increase zsh-autocomplete delay
zstyle ':autocomplete:*' delay 0.1

# Don't add spaces after accepting an option
zstyle ':autocomplete:*' add-space ""

zinit ice lucid wait \
  depth"1" src"zsh-autocomplete.plugin.zsh"
zinit light wochap/zsh-autocomplete

## zsh-fsh

zinit ice lucid wait \
  atinit"ZINIT[COMPINIT_OPTS]=-C; zicompinit; zicdreplay" \
  atload"fast-theme XDG:catppuccin-mocha --quiet" \
  depth"1" src"fast-syntax-highlighting.plugin.zsh"
zinit light zdharma-continuum/fast-syntax-highlighting

## zsh-autosuggestions

export ZSH_AUTOSUGGEST_MANUAL_REBIND=true
export ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# TODO: at load show suggestions of current text
zinit ice lucid wait"1" \
  atload"!_zsh_autosuggest_start" \
  depth"1" src"zsh-autosuggestions.plugin.zsh"
zinit light zsh-users/zsh-autosuggestions

## zsh-history-substring-search

# https://github.com/zsh-users/zsh-history-substring-search
# change the behavior of history-substring-search-up
export HISTORY_SUBSTRING_SEARCH_PREFIXED="1"

export HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND="bg=cyan,fg=16,bold"
export HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_NOT_FOUND="bg=red,fg=16,bold"

zinit ice lucid wait"1" \
  depth"1" src"zsh-history-substring-search.plugin.zsh"
zinit light zsh-users/zsh-history-substring-search

## zsh-abbr

function _setup_zsh_abbr() {
  if [[ ! -e "$ABBR_USER_ABBREVIATIONS_FILE" || ! -s "$ABBR_USER_ABBREVIATIONS_FILE" ]]; then
    abbr import-aliases --quiet
    abbr erase --quiet nv
    abbr erase --quiet nvim
    abbr erase --quiet ls
    abbr erase --quiet la
    abbr erase --quiet lt
    abbr erase --quiet ll
    abbr erase --quiet lla
    abbr erase --quiet z
  fi
}

zinit ice lucid wait"1" \
  atload"_setup_zsh_abbr" \
  cp"man/man1/abbr.1 -> $ZINIT[MAN_DIR]/man1/abbr.1" \
  depth"1" src"zsh-abbr.plugin.zsh"
zinit light olets/zsh-abbr

## zsh-vi-mode

export ZVM_INIT_MODE=sourcing
export ZVM_LAZY_KEYBINDINGS=false

function load_key_bindings() {
  source ~/.config/zsh/key-bindings-vi.zsh

  # HACK: fix race condition where zsh-vi-mode overwrites fzf key-binding
  bindkey -M viins '^R' fzf-history-widget
}

function zvm_config() {
  ZVM_VI_INSERT_ESCAPE_BINDKEY=^X
  ZVM_VI_HIGHLIGHT_BACKGROUND=#45475A
  ZVM_VI_HIGHLIGHT_FOREGROUND=#cdd6f4
  ZVM_VI_SURROUND_BINDKEY=s-prefix
  ZVM_ESCAPE_KEYTIMEOUT=0
  ZVM_LINE_INIT_MODE=$ZVM_MODE_LAST
  ZVM_INSERT_MODE_CURSOR=$ZVM_CURSOR_BLINKING_BEAM
  ZVM_OPPEND_MODE_CURSOR=$ZVM_CURSOR_BLINKING_BLOCK
}

typeset -g VI_MODE
VI_MODE="%B%F{#1E1E2E}%K{#a6e3a1} INSERT %k%f%b"
function zvm_after_select_vi_mode() {
  case $ZVM_MODE in
    $ZVM_MODE_NORMAL)
      VI_MODE="%B%F{#1E1E2E}%K{#b4befe} NORMAL %k%f%b"
    ;;
    $ZVM_MODE_INSERT)
      VI_MODE="%B%F{#1E1E2E}%K{#a6e3a1} INSERT %k%f%b"
    ;;
    $ZVM_MODE_VISUAL)
      VI_MODE="%B%F{#1E1E2E}%K{#f2cdcd} VISUAL %k%f%b"
    ;;
    $ZVM_MODE_VISUAL_LINE)
      VI_MODE="%B%F{#1E1E2E}%K{#f2cdcd} V-LINE %k%f%b"
    ;;
    $ZVM_MODE_REPLACE)
      VI_MODE="%B%F{#1E1E2E}%K{#eba0ac} REPLACE %k%f%b"
    ;;
  esac
}

# TODO: keybindings doesn't load before zsh-vi-mode keybindings
function zvm_after_init() {
  load_key_bindings
}

zinit ice lucid wait \
  atload"load_key_bindings" \
  depth"1" src"zsh-vi-mode.plugin.zsh"
zinit light wochap/zsh-vi-mode

## fzf

zinit ice lucid wait \
  multisrc"shell/{completion,key-bindings}.zsh" \
  id-as"junegunn/fzf_completions" \
  pick"/dev/null" \
  has"fzf" \
  depth"1"
zinit light junegunn/fzf

## fuzzy-sys

zinit ice lucid wait"1" \
  depth"1" src"fuzzy-sys.plugin.zsh"
zinit light NullSense/fuzzy-sys

## omz

zinit ice svn
zinit snippet OMZP::aliases

zinit ice lucid wait"1"
zinit snippet OMZP::dirhistory

## zsh-completions

zinit ice lucid wait"2" \
  atinit"ZINIT[COMPINIT_OPTS]=-C; zicompinit; zicdreplay" \
  as"completion" \
  blockf \
  depth"1"
zinit light zsh-users/zsh-completions

## zoxide

zinit ice lucid wait \
  depth"1" src"zoxide.plugin.zsh"
zinit light ajeetdsouza/zoxide

## navi

zinit ice lucid wait"1" \
  src"shell/navi.plugin.zsh" \
  id-as"denisidoro/plugin_navi" \
  pick"/dev/null" \
  has"navi" \
  depth"1"
zinit light denisidoro/navi

## nix-index

# TODO: doesn't work?
zinit ice lucid wait"1" as"snippet"
zinit snippet ~/.config/zsh/nix-store/command-not-found.sh

