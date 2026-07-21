# wt — git worktree manager shell integration
# source this in .bashrc / .zshrc:
#   source /path/to/wt.sh

wt() {
  case "${1:-}" in
  switch | clone)
    local dir
    dir="$(command wt "$@")" && cd "$dir"
    ;;
  rm)
    command wt "$@"
    if [[ ! -d "$PWD" ]]; then
      local default_dir
      default_dir="$(command wt switch)" && cd "$default_dir"
    fi
    ;;
  *)
    command wt "$@"
    ;;
  esac
}
