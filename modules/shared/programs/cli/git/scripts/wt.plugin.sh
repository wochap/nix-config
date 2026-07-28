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
    local fallback_dir
    fallback_dir="$(command wt switch)"
    command wt "$@"
    if [[ ! -d "$PWD" ]]; then
      cd "$fallback_dir"
    fi
    ;;
  *)
    command wt "$@"
    ;;
  esac
}
