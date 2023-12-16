function timezsh() {
  shell=${1-$SHELL}
  for i in $(seq 1 10); do time $shell -i -c exit; done
}

# cd into git repository
function pro() {
  projects=$(find ~/.config -maxdepth 2 -name ".git" -type d -execdir pwd \;)
  projects+="\n"
  projects+=$(find ~/Projects -maxdepth 3 -name ".git" -type d -execdir pwd \;)
  projects+="\n"
  projects+=$(find ~ -maxdepth 2 -name ".git" -type d -execdir pwd \;)

  selected=$(echo "$projects" | FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS-} ${FZF_CTRL_T_OPTS-} --preview 'lsd -l -A --tree --depth=1 --color=always --blocks=size,name {} | head -200'" fzf)

  if [[ -n "$selected" ]]; then
    cd "$selected"
    zle reset-prompt 2>/dev/null
  fi
}
zle -N pro

# cd into git repository
function apro() {
  projects=$(find ~ -maxdepth 4 -name ".git" -type d -execdir pwd \;)

  selected=$(echo "$projects" | FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS-} ${FZF_CTRL_T_OPTS-} --preview 'lsd -l -A --tree --depth=1 --color=always --blocks=size,name {} | head -200'" fzf)

  if [[ -n "$selected" ]]; then
    cd "$selected"
    zle reset-prompt 2>/dev/null
  fi
}
zle -N apro

function killport {
  kill $(lsof -t -i:"$1") > /dev/null 2>&1
}

function opro() {
  scripts=$(find /etc/scripts/projects -type l,f -name "*.sh")

  $(echo "$scripts" | FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS-} ${FZF_CTRL_T_OPTS-}" fzf)
}
zle -N opro

function scripts() {
  scripts=$(find /etc/scripts -type l,f -name "*.sh")

  $(echo "$scripts" | fzf)
}

# run npm script (requires jq)
function fns() {
  local script
  script=$(cat package.json | jq -r '.scripts | keys[] ' | sort | fzf) && npm run $(echo "$script")
}

# play song with mpc
function fmpc() {
  local song_position
  song_position=$(mpc -f "%position%) %artist% - %title%" playlist | \
    fzf-tmux --query="$1" --reverse --select-1 --exit-0 | \
    sed -n 's/^\([0-9]\+\)).*/\1/p') || return 1
  [ -n "$song_position" ] && mpc -q play $song_position
}

# HACK: remove padding inside kitty
function run-without-kpadding() {
  if [[ -n $KITTY_PID ]]; then
    kitty @ set-spacing padding=0
    "$@"
    kitty @ set-spacing padding=7
  else
    "$@"
  fi
}

# switch between nvim configurations
function nvims() {
  items=$(find $HOME/.config -maxdepth 2 -name "init.lua" -type f -execdir sh -c 'pwd | xargs basename' \;)
  selected=$(printf "%s\n" "${items[@]}" | FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS-} ${FZF_CTRL_T_OPTS-} --preview 'lsd -l -A --tree --depth=1 --color=always --blocks=size,name ~/.config/{} | head -200'" fzf )
  if [[ -z $selected ]]; then
    return 0
  elif [[ $selected == "nvim" ]]; then
    selected=""
  fi
  NVIM_APPNAME=$selected nvim "$@"
}
alias nvs=nvims

function copyfile() {
  wl-copy < $1
}

function copybuffer() {
	printf "%s" "$BUFFER" | wl-copy -n
}
zle -N copybuffer

function disappointed() {
  echo -n " ಠ_ಠ " | tee /dev/tty | wl-copy;
}

function flip() {
  echo -n "（╯°□°）╯ ┻━┻" | tee /dev/tty | wl-copy;
}

function shrug() {
  echo -n "¯\_(ツ)_/¯" | tee /dev/tty | wl-copy;
}

# Highlighting --help messages with bat
function help() {
  "$@" --help 2>&1 | bathelp
}

function f()
{
  # Block nesting of nnn in subshells
  if [[ "${NNNLVL:-0}" -ge 1 ]]; then
    echo "nnn is already running"
    return
  fi

  # The behaviour is set to cd on quit (nnn checks if NNN_TMPFILE is set)
  # If NNN_TMPFILE is set to a custom path, it must be exported for nnn to
  # see. To cd on quit only on ^G, remove the "export" and make sure not to
  # use a custom path, i.e. set NNN_TMPFILE *exactly* as follows:
  #     NNN_TMPFILE="${XDG_CONFIG_HOME:-$HOME/.config}/nnn/.lastd"
  export NNN_TMPFILE="${XDG_CONFIG_HOME:-$HOME/.config}/nnn/.lastd"

  # Unmask ^Q (, ^V etc.) (if required, see `stty -a`) to Quit nnn
  # stty start undef
  # stty stop undef
  # stty lwrap undef
  # stty lnext undef

  # The backslash allows one to alias n to nnn if desired without making an
  # infinitely recursive alias
  \nnn -a "$@"

  if [ -f "$NNN_TMPFILE" ]; then
    . "$NNN_TMPFILE"
    rm -f "$NNN_TMPFILE" > /dev/null
  fi
}

# TODO: fix bug with zsh-vi-mode
# can't enter vicmd mode if you do Ctrl+c when in vicmd
# TODO: it also hide dotfiles in complete menu
# # transient prompt for starship
# zle-line-init() {
#   emulate -L zsh
#
#   [[ $CONTEXT == start ]] || return 0
#
#   while true; do
#     zle .recursive-edit
#     local -i ret=$?
#     [[ $ret == 0 && $KEYS == $'\4' ]] || break
#     [[ -o ignore_eof ]] || exit 0
#   done
#
#   local saved_prompt=$PROMPT
#   local saved_rprompt=$RPROMPT
#   PROMPT='$(STARSHIP_CONFIG=~/.config/starship-transient.toml starship prompt --terminal-width="$COLUMNS" --keymap="${KEYMAP:-}" --status="$STARSHIP_CMD_STATUS" --pipestatus="${STARSHIP_PIPE_STATUS[*]}" --cmd-duration="${STARSHIP_DURATION:-}" --jobs="$STARSHIP_JOBS_COUNT")'
#   RPROMPT=''
#   zle .reset-prompt
#   PROMPT=$saved_prompt
#   RPROMPT=$saved_rprompt
#
#   if (( ret )); then
#     zle .send-break
#   else
#     zle .accept-line
#   fi
#   return ret
# }
#
# zle -N zle-line-init

