function timezsh() {
  shell=${1-$SHELL}
  for i in $(seq 1 10); do time $shell -i -c exit; done
}

function projects() {
  projects=$(find ~ ~/.config -maxdepth 2 -name ".git" -type d -execdir pwd \;)
  if [ -n "$projects" ]; then
    _projects=$(find ~/Projects -maxdepth 3 -name ".git" -type d -execdir pwd \;)
    if [ -n "$_projects" ]; then
      projects+="\n"
      projects+="$_projects"
    fi
  fi
  echo "$projects"
}

# cd into git repository
function pro() {
  selected=$(projects | FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS-} ${FZF_CTRL_T_OPTS-} --preview 'lsd -l -A --tree --depth=1 --color=always --blocks=size,name {} | head -200'" fzf)

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
  scripts=$(find ~/.config/scripts /etc/scripts/projects -type l,f -name "*.sh")

  selected=$(echo "$scripts" | FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS-} ${FZF_CTRL_T_OPTS-}" fzf)

  if [[ -n "$selected" ]]; then
    sh $selected
  fi
}
zle -N opro

function cdfzf() {
  dirs=$(fd --type d --max-depth 1 --fixed-strings --no-ignore --hidden --exclude node_modules --exclude .git --exclude .direnv)

  selected=$(echo "$dirs" | FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS-} ${FZF_ALT_C_OPTS-}" fzf)

  if [[ -n "$selected" ]]; then
    cd "$selected"
    zle reset-prompt 2>/dev/null
  fi
}
zle -N cdfzf

function scripts() {
  scripts=$(find /etc/scripts -type l,f -name "*.sh")

  sh $(echo "$scripts" | fzf)
}

# run npm script (requires jq)
function fns() {
  local script
  script=$(cat ./package.json | jq -r '.scripts | keys[] ' | sort | FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS-} ${FZF_CTRL_R_OPTS-}" fzf --preview 'cat package.json | jq -r '.scripts.{}' | bat --plain --language=sh --color=always')
  npm run $(echo "$script")
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
  NVIM_APPNAME=$selected run-without-kpadding nvim "$@"
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
