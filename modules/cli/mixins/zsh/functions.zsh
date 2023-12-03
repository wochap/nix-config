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
    cd $selected
  fi
}
zle -N pro
bindkey '^[up' pro

# cd into git repository
function apro() {
  projects=$(find ~ -maxdepth 4 -name ".git" -type d -execdir pwd \;)

  selected=$(echo "$projects" | FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS-} ${FZF_CTRL_T_OPTS-} --preview 'lsd -l -A --tree --depth=1 --color=always --blocks=size,name {} | head -200'" fzf)

  if [[ -n "$selected" ]]; then
    cd $selected
  fi
}
zle -N apro
bindkey '^[ua' apro

function killport {
  kill $(lsof -t -i:"$1") > /dev/null 2>&1
}

function opro() {
  projects=$(find /etc/scripts/projects -type l,f -name "*.sh")

  $(echo "$projects" | FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS-} ${FZF_CTRL_T_OPTS-}" fzf)
}
zle -N opro
bindkey '^[uo' opro

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
