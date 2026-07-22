#compdef wt

_wt() {
  local -a commands
  commands=(
    'clone:Clone repo as bare + default worktree'
    'switch:Switch to worktree (create if missing)'
    'list:List all worktrees'
    'rm:Remove worktree + branch'
    'help:Show help message'
  )

  # Find current subcommand
  local subcmd
  for ((i = 2; i < CURRENT; i++)); do
    case "${words[i]}" in
      clone|switch|list|rm|help) subcmd="${words[i]}"; break ;;
    esac
  done

  if [[ -z "$subcmd" ]]; then
    _describe 'command' commands
    return
  fi

  case "$subcmd" in
    clone)
      # No dynamic completions for clone (URL argument)
      ;;

    switch)
      # Flags
      if [[ "$words[CURRENT-1]" == -* ]]; then
        return
      fi

      # Check if -b mode — complete from-ref or nothing
      local has_b=0
      for ((i = 2; i < CURRENT; i++)); do
        [[ "${words[i]}" == "-b" ]] && has_b=1
      done

      if [[ $has_b -eq 1 ]]; then
        # After -b <branch>, complete optional <from> ref
        # Skip — non-essential per design
        return
      fi

      # Dynamic branch + commit completions
      local git_dir
      git_dir=$(git rev-parse --git-common-dir 2>/dev/null) || return
      git_dir=$(cd "$git_dir" && pwd -P)
      [[ "$(git -C "$git_dir" rev-parse --is-bare-repository 2>/dev/null)" != "true" ]] && return

      local -a branches remotes commits

      # Local branches
      while IFS= read -r line; do
        [[ -n "$line" ]] && branches+=("$line")
      done < <(git -C "$git_dir" branch --format='%(refname:short)' 2>/dev/null)

      # Remote branches
      while IFS= read -r line; do
        [[ -n "$line" && "$line" != "HEAD" ]] && remotes+=("$line")
      done < <(git -C "$git_dir" branch -r --format='%(refname:lstrip=3)' 2>/dev/null)

      # Commit hashes (recent 20)
      while IFS= read -r line; do
        [[ -n "$line" ]] && commits+=("$line")
      done < <(git -C "$git_dir" log --oneline -20 --format='%h' 2>/dev/null)

      local -a all_completions
      if (( ${#branches} )); then
        all_completions+=("${branches[@]/%/:local branch}")
      fi
      if (( ${#remotes} )); then
        all_completions+=("${remotes[@]/%/:remote branch}")
      fi
      if (( ${#commits} )); then
        all_completions+=("${commits[@]/%/:commit}")
      fi

      _describe 'ref' all_completions

      # Also offer -b flag
      local -a flags
      flags=('-b:create new branch')
      _describe 'flag' flags
      ;;

    list)
      # No arguments
      ;;

    rm)
      # Flags
      local -a flags
      flags=(
        '--remote:also delete remote branch'
        '--force:allow removing dirty worktree'
      )

      # Check if first positional arg already given
      local has_name=0
      for ((i = 2; i < CURRENT; i++)); do
        [[ "${words[i]}" != -* ]] && has_name=1
      done

      if [[ $has_name -eq 0 ]]; then
        # Complete worktree directory names
        local git_dir
        git_dir=$(git rev-parse --git-common-dir 2>/dev/null) || return
        git_dir=$(cd "$git_dir" && pwd -P)
        [[ "$(git -C "$git_dir" rev-parse --is-bare-repository 2>/dev/null)" != "true" ]] && return

        local root
        root=$(dirname "$git_dir")

        local -a worktrees
        while IFS= read -r line; do
          local path="${line#worktree }"
          local rel="${path#"$root"/}"
          [[ -n "$rel" && "$rel" != "$path" ]] && worktrees+=("$rel")
        done < <(git -C "$git_dir" worktree list --porcelain 2>/dev/null | grep '^worktree ')

        if (( ${#worktrees} )); then
          _describe 'worktree' worktrees
        fi
      fi

      _describe 'flag' flags
      ;;

    help)
      # No arguments
      ;;
  esac
}

compdef _wt wt
