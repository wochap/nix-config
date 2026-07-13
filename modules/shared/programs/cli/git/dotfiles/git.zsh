# source: https://stackoverflow.com/questions/5189560/how-do-i-squash-my-last-n-commits-together
function gsquash() {
  # Reset the current branch to the commit just before the last 12:
  git reset --hard "HEAD~$1"

  # HEAD@{1} is where the branch was just before the previous command.
  # This command sets the state of the index to be as it would just
  # after a merge from that commit:
  git merge --squash HEAD@{1}
}

function gundo() {
  # Undo last commit
  git reset --soft "HEAD~"
}

function gpoforce() {
  branch_name=$(git rev-parse --abbrev-ref HEAD)
  git push origin $branch_name --force
}

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
  local items=(*(N))

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

# diff-target [-2] [target] [git diff args...]
# Diff current branch vs target (default: origin/HEAD -> development/main/master).
# Three-dot (merge-base) by default; -2 for plain two-dot.
diff-target() {
  local two_dot=0 target="" cand
  if [[ "${1:-}" == "-2" ]]; then
    two_dot=1
    shift
  fi
  if [[ $# -gt 0 && "$1" != -* ]]; then
    target="$1"
    shift
  fi
  [[ "${1:-}" == "--" ]] && shift

  if [[ -z "$target" ]]; then
    target=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null)
    if [[ -z "$target" ]]; then
      for cand in development main master; do
        if git show-ref --verify --quiet "refs/heads/$cand"; then
          target=$cand
          break
        fi
      done
    fi
    if [[ -z "$target" ]]; then
      print -u2 "error: cannot detect default branch; pass target explicitly"
      return 1
    fi
  fi

  if ! git rev-parse --verify --quiet "$target^{commit}" >/dev/null; then
    print -u2 "error: '$target' is not a valid branch/commit"
    return 1
  fi

  if ((two_dot)); then
    git diff "$target" HEAD "$@"
  else
    git diff "$target...HEAD" "$@"
  fi
}
compdef _git diff-target=git-diff
