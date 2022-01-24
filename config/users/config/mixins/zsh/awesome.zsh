# cd into git repository
function pro() {
  projects=$(find ~/.config -maxdepth 1 -type d -execdir test -d {}/.git \; -print -prune)
  projects+="\n"
  projects+=$(find ~/Projects -maxdepth 2 -type d -execdir test -d {}/.git \; -print -prune)
  projects+="\n"
  projects+=$(find ~/ -maxdepth 1 -type d -execdir test -d {}/.git \; -print -prune)

  cd $(echo "$projects" | fzf)
}

function killport {
  kill $(lsof -t -i:"$1")
}

function killreceptacles {
  while bspc node 'any.leaf.!window' -k; do :; done
}

function opro() {
  projects=$(find /etc/scripts/projects -type f -name "*.sh")

  $(echo "$projects" | fzf)
}

function scripts() {
  scripts=$(find /etc/scripts -type f -name "*.sh")

  $(echo "$scripts" | fzf)
}

# run npm script (requires jq)
function fns() {
  local script
  script=$(cat package.json | jq -r '.scripts | keys[] ' | sort | fzf) && npm run $(echo "$script")
}

function open_command() {
  local open_cmd

  # define the open command
  case "$OSTYPE" in
    darwin*)  open_cmd='open' ;;
    cygwin*)  open_cmd='cygstart' ;;
    linux*)   [[ "$(uname -r)" != *icrosoft* ]] && open_cmd='nohup xdg-open' || {
                open_cmd='cmd.exe /c start ""'
                [[ -e "$1" ]] && { 1="$(wslpath -w "${1:a}")" || return 1 }
              } ;;
    msys*)    open_cmd='start ""' ;;
    *)        echo "Platform $OSTYPE not supported"
              return 1
              ;;
  esac

  ${=open_cmd} "$@" &>/dev/null
}

