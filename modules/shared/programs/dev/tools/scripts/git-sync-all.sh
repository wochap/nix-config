#!/usr/bin/env bash

# Recursively search for Git repositories under a path whose origin remote
# matches GitHub user wochap (or configured user), and if clean, fetches and pulls.
# Dry run by default: lists repositories and actions without pulling.

set -euo pipefail

usage() {
  cat <<EOF
Usage: git-sync-all [OPTIONS] [PATH]

Recursively find git repositories under PATH (default: .) whose origin remote
matches GitHub user 'wochap' (or specified user), and if working tree is clean,
fetches and pulls changes.

Without --yes it only inspects repositories and reports what would be pulled (dry run).

Options:
  -y, --yes          actually pull changes (default: dry run)
  -u, --user USER    GitHub user/organization to match (default: wochap)
  -n, --no-fetch     skip git fetch (inspect against existing local/remote refs)
  -h, --help         show this help message
EOF
}

APPLY=0
TARGET_USER="wochap"
DO_FETCH=1
ROOT="."

while [[ $# -gt 0 ]]; do
  case "$1" in
  -y | --yes) APPLY=1 ;;
  -u | --user)
    TARGET_USER="${2:?--user requires a username}"
    shift
    ;;
  -n | --no-fetch) DO_FETCH=0 ;;
  -h | --help)
    usage
    exit 0
    ;;
  -*)
    echo "unknown option: $1" >&2
    usage >&2
    exit 1
    ;;
  *) ROOT="$1" ;;
  esac
  shift
done

# Expand leading tilde if present
ROOT="${ROOT/#\~/$HOME}"

if [[ ! -d "$ROOT" ]]; then
  echo "not a directory: $ROOT" >&2
  exit 1
fi

if [[ -t 1 ]]; then
  C_RESET="\033[0m"
  C_BOLD="\033[1m"
  C_DIM="\033[2m"
  C_GREEN="\033[0;32m"
  C_YELLOW="\033[0;33m"
  C_BLUE="\033[0;34m"
  C_CYAN="\033[0;36m"
  C_RED="\033[0;31m"
else
  C_RESET=""
  C_BOLD=""
  C_DIM=""
  C_GREEN=""
  C_YELLOW=""
  C_BLUE=""
  C_CYAN=""
  C_RED=""
fi

# Find all .git directories/files while skipping common heavy caches and dependencies
mapfile -d '' GIT_ENTRIES < <(
  find "$ROOT" \
    \( -name .direnv -o -name node_modules -o -name target -o -name .cache -o -name dist -o -name build \) -prune \
    -o -name .git -prune -print0 2>/dev/null
)

# Case-insensitive match for GitHub URLs
shopt -s nocasematch
pattern="^((https?|git|ssh)://)?(git@)?github\.com(:[0-9]+)?[:/]${TARGET_USER}/([^/]+?)(\.git)?/?$"

list_succeeded=()
list_would_pull=()
list_skipped_uptodate=()
list_skipped_dirty=()
list_skipped_other=()
list_failed=()

for git_entry in "${GIT_ENTRIES[@]}"; do
  repo_dir=$(dirname "$git_entry")
  repo_dir="${repo_dir%/}"
  if [[ "$repo_dir" == "." || "$repo_dir" == "./." ]]; then
    repo_dir="."
  elif [[ "$repo_dir" != /* ]]; then
    repo_dir="./${repo_dir#./}"
  fi

  origin_url=$(git -C "$repo_dir" config --get remote.origin.url 2>/dev/null || true)
  if [[ -z "$origin_url" ]]; then
    continue
  fi

  if [[ ! "$origin_url" =~ $pattern ]]; then
    continue
  fi

  repo_name="${BASH_REMATCH[5]}"
  repo_name="${repo_name%.git}"

  # Step 1: Check if working tree is clean
  status_porcelain=$(git -C "$repo_dir" status --porcelain 2>/dev/null || true)
  if [[ -n "$status_porcelain" ]]; then
    changed_count=$(echo "$status_porcelain" | wc -l | tr -d ' ')
    list_skipped_dirty+=("$repo_dir ($changed_count uncommitted change(s))")
    printf "${C_YELLOW}[SKIPPED - DIRTY]${C_RESET} %s ${C_DIM}(%s uncommitted changes)${C_RESET}\n" "$repo_dir" "$changed_count"
    continue
  fi

  # Step 2: Fetch remote origin (if DO_FETCH is enabled)
  if ((DO_FETCH)); then
    if ! fetch_err=$(git -C "$repo_dir" fetch --quiet origin 2>&1); then
      err_msg=$(echo "$fetch_err" | tr '\n' ' ' | sed 's/[[:space:]]\+/ /g')
      list_failed+=("$repo_dir (fetch failed: ${err_msg:-unknown error})")
      printf "${C_RED}[FAILED]${C_RESET}          %s ${C_DIM}(git fetch origin failed)${C_RESET}\n" "$repo_dir"
      continue
    fi
  fi

  # Step 3: Determine current branch
  branch=$(git -C "$repo_dir" symbolic-ref --short -q HEAD 2>/dev/null || true)
  if [[ -z "$branch" ]]; then
    head_commit=$(git -C "$repo_dir" rev-parse --short HEAD 2>/dev/null || echo "unknown")
    list_skipped_other+=("$repo_dir (detached HEAD at $head_commit)")
    printf "${C_YELLOW}[SKIPPED]${C_RESET}          %s ${C_DIM}(detached HEAD at %s)${C_RESET}\n" "$repo_dir" "$head_commit"
    continue
  fi

  # Step 4: Resolve upstream branch
  upstream=$(git -C "$repo_dir" rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || true)
  has_configured_upstream=1
  if [[ -z "$upstream" ]]; then
    has_configured_upstream=0
    if git -C "$repo_dir" rev-parse --verify --quiet "origin/$branch" >/dev/null 2>&1; then
      upstream="origin/$branch"
    fi
  fi

  if [[ -z "$upstream" ]]; then
    list_skipped_other+=("$repo_dir (branch '$branch' has no remote tracking branch on origin)")
    printf "${C_YELLOW}[SKIPPED]${C_RESET}          %s ${C_DIM}(branch '%s' has no upstream)${C_RESET}\n" "$repo_dir" "$branch"
    continue
  fi

  # Step 5: Check ahead and behind counts
  behind=$(git -C "$repo_dir" rev-list --count "HEAD..$upstream" 2>/dev/null || echo 0)
  ahead=$(git -C "$repo_dir" rev-list --count "$upstream..HEAD" 2>/dev/null || echo 0)

  if ((behind == 0 && ahead == 0)); then
    list_skipped_uptodate+=("$repo_dir ($branch)")
    printf "${C_CYAN}[UP TO DATE]${C_RESET}       %s ${C_DIM}(%s)${C_RESET}\n" "$repo_dir" "$branch"
  elif ((behind == 0 && ahead > 0)); then
    list_skipped_uptodate+=("$repo_dir ($branch, ahead by $ahead commit(s))")
    printf "${C_CYAN}[UP TO DATE]${C_RESET}       %s ${C_DIM}(%s, ahead by %d)${C_RESET}\n" "$repo_dir" "$branch" "$ahead"
  elif ((behind > 0 && ahead > 0)); then
    list_failed+=("$repo_dir (diverged on $branch: ahead $ahead, behind $behind)")
    printf "${C_RED}[DIVERGED]${C_RESET}        %s ${C_DIM}(%s: ahead %d, behind %d)${C_RESET}\n" "$repo_dir" "$branch" "$ahead" "$behind"
  else
    # behind > 0 && ahead == 0
    if ((APPLY)); then
      pull_err=""
      if ((has_configured_upstream)); then
        pull_ok=$(git -C "$repo_dir" pull --ff-only 2>&1) || pull_err="$pull_ok"
      else
        pull_ok=$(git -C "$repo_dir" pull --ff-only origin "$branch" 2>&1) || pull_err="$pull_ok"
        # If successfully pulled, set upstream tracking
        if [[ -z "$pull_err" ]]; then
          git -C "$repo_dir" branch --set-upstream-to="origin/$branch" "$branch" 2>/dev/null || true
        fi
      fi

      if [[ -z "$pull_err" ]]; then
        list_succeeded+=("$repo_dir ($branch, pulled $behind commit(s))")
        printf "${C_GREEN}[PULLED]${C_RESET}          %s ${C_DIM}(%s, +%d commit(s))${C_RESET}\n" "$repo_dir" "$branch" "$behind"
      else
        err_msg=$(echo "$pull_err" | tr '\n' ' ' | sed 's/[[:space:]]\+/ /g')
        list_failed+=("$repo_dir (pull failed: ${err_msg:-unknown error})")
        printf "${C_RED}[FAILED]${C_RESET}          %s ${C_DIM}(pull failed)${C_RESET}\n" "$repo_dir"
      fi
    else
      list_would_pull+=("$repo_dir ($branch, $behind new commit(s))")
      printf "${C_GREEN}[WOULD PULL]${C_RESET}      %s ${C_DIM}(%s, %d new commit(s))${C_RESET}\n" "$repo_dir" "$branch" "$behind"
    fi
  fi
done

echo
echo -e "${C_BOLD}=== Summary ===${C_RESET}"

if ((APPLY)); then
  if ((${#list_succeeded[@]} > 0)); then
    printf "${C_GREEN}Successfully pulled (%d):${C_RESET}\n" "${#list_succeeded[@]}"
    for item in "${list_succeeded[@]}"; do
      echo "  ✓ $item"
    done
  fi
else
  if ((${#list_would_pull[@]} > 0)); then
    printf "${C_GREEN}Would pull (%d):${C_RESET}\n" "${#list_would_pull[@]}"
    for item in "${list_would_pull[@]}"; do
      echo "  ➜ $item"
    done
  fi
fi

if ((${#list_skipped_uptodate[@]} > 0)); then
  printf "${C_CYAN}Skipped - up to date (%d):${C_RESET}\n" "${#list_skipped_uptodate[@]}"
  for item in "${list_skipped_uptodate[@]}"; do
    echo "  - $item"
  done
fi

if ((${#list_skipped_dirty[@]} > 0)); then
  printf "${C_YELLOW}Skipped - dirty working tree (%d):${C_RESET}\n" "${#list_skipped_dirty[@]}"
  for item in "${list_skipped_dirty[@]}"; do
    echo "  ! $item"
  done
fi

if ((${#list_skipped_other[@]} > 0)); then
  printf "${C_YELLOW}Skipped - other (%d):${C_RESET}\n" "${#list_skipped_other[@]}"
  for item in "${list_skipped_other[@]}"; do
    echo "  ? $item"
  done
fi

if ((${#list_failed[@]} > 0)); then
  printf "${C_RED}Failed / errors (%d):${C_RESET}\n" "${#list_failed[@]}"
  for item in "${list_failed[@]}"; do
    echo "  ✗ $item"
  done
fi

total_matched=$(( ${#list_succeeded[@]} + ${#list_would_pull[@]} + ${#list_skipped_uptodate[@]} + ${#list_skipped_dirty[@]} + ${#list_skipped_other[@]} + ${#list_failed[@]} ))
total_skipped=$(( ${#list_skipped_uptodate[@]} + ${#list_skipped_dirty[@]} + ${#list_skipped_other[@]} ))
echo
if ((total_matched == 0)); then
  echo "No repositories matching GitHub user '$TARGET_USER' found under $ROOT."
else
  if ((APPLY)); then
    echo -e "${C_BOLD}Total:${C_RESET} $total_matched matching repo(s) (${#list_succeeded[@]} updated, $total_skipped skipped, ${#list_failed[@]} failed)"
  else
    echo -e "${C_BOLD}Total:${C_RESET} $total_matched matching repo(s) (${#list_would_pull[@]} to update, $total_skipped skipped, ${#list_failed[@]} failed)"
    if ((${#list_would_pull[@]} > 0)); then
      echo -e "${C_YELLOW}Dry run complete.${C_RESET} Run with ${C_BOLD}--yes${C_RESET} to apply changes."
    fi
  fi
fi
