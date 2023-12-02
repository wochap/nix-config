function timezsh() {
  shell=${1-$SHELL}
  for i in $(seq 1 10); do time $shell -i -c exit; done
}

# cd into git repository
function pro() {
  projects=$(find ~/.config -maxdepth 1 -type d -execdir test -d {}/.git \; -print -prune)
  projects+="\n"
  projects+=$(find ~/Projects -maxdepth 2 -type d -execdir test -d {}/.git \; -print -prune)
  projects+="\n"
  projects+=$(find ~/ -maxdepth 1 -type d -execdir test -d {}/.git \; -print -prune)

  selected=$(echo "$projects" | fzf)

  if [[ -n "$selected" ]]; then
    cd $selected
  fi
}

function killport {
  kill $(lsof -t -i:"$1") > /dev/null 2>&1
}

function opro() {
  projects=$(find /etc/scripts/projects -type l,f -name "*.sh")

  $(echo "$projects" | fzf)
}

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
