# regular files, ignore directories, ignore symlinks
_cpf_files_only() {
  _files -g '*(-.)'
}

function print-terminal-colors() {
  for i in {0..255}; do
    echo -e "$(tput setaf $i)This is color 󱓻 $i$(tput sgr0)";
  done
}

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
# git repo in projects dir
function pro() {
  selected=$(projects | FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS-} ${FZF_CTRL_T_OPTS-} --preview 'lsd -l -A --tree --depth=1 --color=always --blocks=size,name {} | head -200'" fzf)

  if [[ -n "$selected" ]]; then
    cd "$selected"
    zle reset-prompt 2>/dev/null
  fi
}
zle -N pro

# cd into git repository
# any git repo in home dir
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
  kill -9 $(lsof -t -i:"$1") > /dev/null 2>&1
}

# automation scripts picker
function opro() {
  scripts=$(find -L ~/.config/scripts /etc/scripts/projects -type l,f -name "*.sh")

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

# run npm script (requires jq)
function fns() {
  local script
  script=$(cat ./package.json | jq -r '.scripts | keys[] ' | sort | FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS-} ${FZF_CTRL_R_OPTS-}" fzf --preview "cat package.json | jq -r '.scripts.\"{}\"' | bat --plain --language=sh --color=always")
  if [[ -n "$script" ]]; then
    npm run $(echo "$script")
  fi
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

# Prints real path of bin
function rp() {
  realpath $(which -- "$@")
}

# add file content to clipboard
function cpfc() {
  local filepath=$(realpath -- "$@")
  cat "$filepath" | wl-copy --type text
}
compdef _cpf_files_only cpfc

# add file to clipboard
# NOTE: doesn't work on thunar
function cpf() {
  local filepath=$(realpath -- "$@")
  printf 'file://%s\n' "$filepath" | wl-copy -t text/uri-list
}
compdef _cpf_files_only cpf

# git-aware directory listing
function gittree() {
  # 1. Argument parsing to toggle between first and last commit
  local mode="last"

  if [[ "$1" == "--first" || "$1" == "-f" ]]; then
    mode="first"
  elif [[ -n "$1" ]]; then
    echo "Usage: gittree [--first|-f]"
    return 1
  fi

  # 2. Zsh-native way to safely gather items handling empty directories via (N) qualifier
  local items=( *(N) )

  [ ${#items[@]} -eq 0 ] && return 0

  # 3. Parallelize git and lsd calls using xargs
  printf "%s\0" "${items[@]}" | env GITTREE_MODE="$mode" xargs -0 -n 1 -P 10 sh -c '
    item="$1"

    [ -d "$item" ] && type_key="1" || type_key="2"

    icon_and_name=$(lsd --icon=always --color=never --directory-only "$item" 2>/dev/null)

    # Check the environment variable to determine which git log command to run
    if [ "$GITTREE_MODE" = "first" ]; then
      log_out=$(git log --reverse --format="%ct|%cd|%h|%s" --date=format:"%a %d %b %H:%M %Y" -- "$item" 2>/dev/null | head -n 1)
    else
      log_out=$(git log -1 --format="%ct|%cd|%h|%s" --date=format:"%a %d %b %H:%M %Y" -- "$item" 2>/dev/null)
    fi

    if [ -z "$log_out" ]; then
      unix_ts="0"
      log_out="Untracked||"
    else
      unix_ts="${log_out%%|*}"
      log_out="${log_out#*|}"
    fi

    # Atomic printf guarantees lines do not interleave in parallel execution
    printf "%s|%s|%s|%s\n" "$type_key" "$unix_ts" "$icon_and_name" "$log_out"
  ' _ | sort -t'|' -k1,1n -k2,2nr | awk -F'|' -v width="$(tput cols 2>/dev/null || echo 80)" '
  {
    # Store rows in memory
    type[NR] = $1
    name[NR] = $3
    date[NR] = $4
    hash[NR] = $5
    msg[NR] = $6

    # Calculate max column widths
    if (length($3) > max_name) max_name = length($3)
    if (length($4) > max_date) max_date = length($4)
    if (length($5) > max_hash) max_hash = length($5)
  }
  END {
    # ANSI Color Codes
    c_blue   = "\033[1;34m"
    c_cyan   = "\033[36m"
    c_yellow = "\033[33m"
    c_dim    = "\033[2m"
    c_reset  = "\033[0m"

    # Pre-calculate available width for truncating
    used_width = max_name + max_date + max_hash + 6
    avail_width = width - used_width

    for (i = 1; i <= NR; i++) {
      # 4. Use native awk sprintf for blazing-fast string padding
      name_str = sprintf("%-*s", max_name, name[i])
      if (type[i] == "1") name_str = c_blue name_str c_reset

      date_str = sprintf("%-*s", max_date, date[i])
      if (date[i] != "Untracked") {
        date_str = c_cyan date_str c_reset
      } else {
        date_str = c_dim date_str c_reset
      }

      hash_str = sprintf("%-*s", max_hash, hash[i])
      if (hash[i] != "") hash_str = c_yellow hash_str c_reset

      # Truncate Message based on terminal width
      msg_str = msg[i]
      if (avail_width > 0 && length(msg_str) > avail_width) {
        msg_str = substr(msg_str, 1, avail_width - 1) "…"
      }

      # Print final colored and aligned row
      printf "%s  %s  %s  %s\n", name_str, date_str, hash_str, msg_str
    }
  }'
}
