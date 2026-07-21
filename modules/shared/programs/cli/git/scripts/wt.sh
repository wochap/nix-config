#!/usr/bin/env bash
set -uo pipefail

# ── Colors ─────────────────────────────────────────────────────────────

if [[ -n "${NO_COLOR:-}" ]]; then
  C_RESET="" C_BOLD="" C_DIM="" C_RED="" C_GREEN="" C_YELLOW="" C_CYAN=""
else
  C_RESET=$'\e[0m'
  C_BOLD=$'\e[1m'
  C_DIM=$'\e[2m'
  C_RED=$'\e[31m'
  C_GREEN=$'\e[32m'
  C_YELLOW=$'\e[33m'
  C_CYAN=$'\e[36m'
fi

die() {
  echo "${C_RED}error: $*${C_RESET}" >&2
  exit 1
}

# Pad a string to a minimum visible width (ignores ANSI escape sequences in length calc)
pad() {
  local str="$1" width="$2"
  local stripped
  stripped=$'\e'
  stripped="${stripped}["
  local visible="${str//${stripped}[^m]*m/}"
  local len=${#visible}
  printf '%s' "$str"
  while ((len < width)); do
    printf ' '
    ((len++))
  done
}

# ── Discovery ──────────────────────────────────────────────────────────

find_project_root() {
  local git_common
  git_common=$(git rev-parse --git-common-dir 2>/dev/null) || {
    echo "error: not inside a git repository" >&2
    return 1
  }
  git_common=$(cd "$git_common" && pwd -P)

  if [[ "$(git -C "$git_common" rev-parse --is-bare-repository 2>/dev/null)" != "true" ]]; then
    echo "error: not a wt project (expected bare repo)" >&2
    echo "hint: use 'wt clone <url>' to create a wt project" >&2
    return 1
  fi

  dirname "$git_common"
}

# ── Helpers ────────────────────────────────────────────────────────────

get_default_branch() {
  local git_dir="$1"
  if git -C "$git_dir" rev-parse --verify refs/heads/main &>/dev/null; then
    echo "main"
    return 0
  fi
  if git -C "$git_dir" rev-parse --verify refs/heads/master &>/dev/null; then
    echo "master"
    return 0
  fi
  local remote_head
  remote_head=$(git -C "$git_dir" symbolic-ref refs/remotes/origin/HEAD 2>/dev/null) || true
  if [[ -n "$remote_head" ]]; then
    echo "${remote_head#refs/remotes/origin/}"
    return 0
  fi
  if git -C "$git_dir" rev-parse --verify refs/remotes/origin/main &>/dev/null; then
    echo "main"
    return 0
  fi
  if git -C "$git_dir" rev-parse --verify refs/remotes/origin/master &>/dev/null; then
    echo "master"
    return 0
  fi
  echo "error: cannot detect default branch" >&2
  return 1
}

resolve_ref() {
  local ref="$1" git_dir="$2"
  if git -C "$git_dir" rev-parse --verify "refs/heads/$ref" &>/dev/null; then
    echo "local-branch"
  elif git -C "$git_dir" rev-parse --verify "refs/remotes/origin/$ref" &>/dev/null; then
    echo "remote-branch"
  elif git -C "$git_dir" rev-parse --verify "$ref^{commit}" &>/dev/null; then
    echo "commit"
  else
    return 1
  fi
}

make_dir_name() {
  local ref_type="$1" ref="$2" name="$3" git_dir="$4"
  case "$ref_type" in
  local-branch | remote-branch)
    local flat="${ref//\//-}"
    if [[ -n "$name" ]]; then
      echo "${flat}-${name}"
    else
      echo "$flat"
    fi
    ;;
  commit)
    if [[ -n "$name" ]]; then
      echo "$name"
    else
      git -C "$git_dir" rev-parse --short=8 "$ref"
    fi
    ;;
  esac
}

# Output: path|head_sha|branch|detached  (one line per worktree, bare entries skipped)
list_worktrees() {
  local git_dir="$1"
  local cur_path="" cur_head="" cur_branch="" cur_bare=0 cur_detached=0
  while IFS= read -r line; do
    case "$line" in
    "worktree "*) cur_path="${line#worktree }" ;;
    "HEAD "*) cur_head="${line#HEAD }" ;;
    "branch "*) cur_branch="${line#branch refs/heads/}" ;;
    "bare") cur_bare=1 ;;
    "detached") cur_detached=1 ;;
    "")
      if [[ $cur_bare -eq 0 && -n "$cur_path" ]]; then
        printf '%s|%s|%s|%d\n' "$cur_path" "$cur_head" "$cur_branch" "$cur_detached"
      fi
      cur_path="" cur_head="" cur_branch="" cur_bare=0 cur_detached=0
      ;;
    esac
  done < <(git -C "$git_dir" worktree list --porcelain)
  if [[ $cur_bare -eq 0 && -n "$cur_path" ]]; then
    printf '%s|%s|%s|%d\n' "$cur_path" "$cur_head" "$cur_branch" "$cur_detached"
  fi
}

find_worktree_for_ref() {
  local git_dir="$1" ref="$2" ref_type="$3"
  local match_sha=""
  if [[ "$ref_type" == "commit" ]]; then
    match_sha=$(git -C "$git_dir" rev-parse "$ref^{commit}" 2>/dev/null) || return 1
  fi
  while IFS='|' read -r path head branch detached; do
    case "$ref_type" in
    local-branch | remote-branch)
      [[ "$branch" == "$ref" ]] && {
        echo "$path"
        return 0
      }
      ;;
    commit)
      [[ "$head" == "$match_sha" ]] && {
        echo "$path"
        return 0
      }
      ;;
    esac
  done < <(list_worktrees "$git_dir")
  return 1
}

find_worktree_by_path() {
  local git_dir="$1" target="$2"
  while IFS='|' read -r path _ _ _; do
    [[ "$path" == "$target" ]] && return 0
  done < <(list_worktrees "$git_dir")
  return 1
}

# ── Commands ───────────────────────────────────────────────────────────

cmd_help() {
  cat <<'EOF'
wt — git worktree manager

Usage:
  wt clone <url> [dir]              Clone repo as bare + default worktree
  wt switch                         Switch to default branch worktree
  wt switch <ref> [name]            Switch to worktree (create if missing)
  wt switch -b <branch> [from]      Create new branch + worktree
  wt list                           List all worktrees
  wt rm <name> [--remote] [--force] Remove worktree + branch

Options:
  --remote    Also delete remote branch (rm)
  --force     Allow removing dirty worktree (rm)

Dir naming:
  branch           → {branch}              (slashes flattened)
  branch + name    → {branch}-{name}       (detached)
  commit           → {hash8}
  commit + name    → {name}                (detached)
  -b branch        → {branch}

Setup:
  source /path/to/wt.sh in .bashrc/.zshrc for cd integration
EOF
}

cmd_clone() {
  local url="${1:-}" dir="${2:-}"
  [[ -z "$url" ]] && die "usage: wt clone <url> [dir]"

  if [[ -z "$dir" ]]; then
    dir=$(basename "$url")
    dir="${dir%.git}"
  fi

  local abs_dir
  abs_dir=$(mkdir -p "$dir" && cd "$dir" && pwd) || die "cannot create directory: $dir"

  git clone --bare "$url" "$abs_dir/.git" || die "clone failed"

  local git_dir="$abs_dir/.git"
  local default_branch
  default_branch=$(get_default_branch "$git_dir") || die "cannot detect default branch"

  git -C "$git_dir" worktree add "$abs_dir/$default_branch" "$default_branch" >&2 ||
    die "failed to create default worktree"

  echo "Cloned into ${C_GREEN}${dir}/${C_RESET}" >&2
  echo "  ${C_DIM}.git/${C_RESET}   (bare)" >&2
  echo "  ${C_GREEN}${default_branch}/${C_RESET}   (worktree)" >&2
  echo "$abs_dir/$default_branch"
}

cmd_switch() {
  local root git_dir
  root=$(find_project_root) || return 1
  git_dir="$root/.git"

  local new_branch=0
  if [[ "${1:-}" == "-b" ]]; then
    new_branch=1
    shift
  fi

  local ref="${1:-}" arg2="${2:-}"

  # ── -b mode: new branch + worktree ──
  if [[ $new_branch -eq 1 ]]; then
    [[ -z "$ref" ]] && die "usage: wt switch -b <branch> [from]"
    local branch="$ref"
    local from="${arg2:-HEAD}"
    local dir_name="${branch//\//-}"

    if git -C "$git_dir" rev-parse --verify "refs/heads/$branch" &>/dev/null; then
      die "branch '$branch' already exists"
    fi
    if [[ -d "$root/$dir_name" ]]; then
      die "directory '$dir_name' already exists"
    fi

    git -C "$git_dir" worktree add -b "$branch" "$root/$dir_name" "$from" >&2 ||
      die "failed to create worktree"
    local short_from
    short_from=$(git -C "$git_dir" rev-parse --short=8 "$from" 2>/dev/null) || short_from="$from"
    echo "Created worktree: ${C_GREEN}${dir_name}${C_RESET} (new branch: ${C_CYAN}${branch}${C_RESET} from ${C_YELLOW}${short_from}${C_RESET})" >&2
    echo "$root/$dir_name"
    return 0
  fi

  # ── no args: switch to default ──
  if [[ -z "$ref" ]]; then
    local default_branch
    default_branch=$(get_default_branch "$git_dir") || return 1
    ref="$default_branch"
  fi

  local name="$arg2"

  # resolve ref type
  local ref_type
  ref_type=$(resolve_ref "$ref" "$git_dir") || die "unknown ref: $ref"

  local dir_name
  dir_name=$(make_dir_name "$ref_type" "$ref" "$name" "$git_dir")

  # check existing worktree
  if [[ -z "$name" ]]; then
    local existing
    if existing=$(find_worktree_for_ref "$git_dir" "$ref" "$ref_type"); then
      echo "$existing"
      return 0
    fi
  else
    if find_worktree_by_path "$git_dir" "$root/$dir_name"; then
      echo "$root/$dir_name"
      return 0
    fi
  fi

  if [[ -d "$root/$dir_name" ]]; then
    die "directory '$dir_name' already exists"
  fi

  # create worktree
  if [[ -n "$name" ]]; then
    git -C "$git_dir" worktree add --detach "$root/$dir_name" "$ref" >&2 ||
      die "failed to create worktree"
    if [[ "$ref_type" == "commit" ]]; then
      local short
      short=$(git -C "$git_dir" rev-parse --short=8 "$ref")
      echo "Created worktree: ${C_GREEN}${dir_name}${C_RESET} (detached at ${C_YELLOW}${short}${C_RESET})" >&2
    else
      echo "Created worktree: ${C_GREEN}${dir_name}${C_RESET} (detached at ${C_YELLOW}${ref} HEAD${C_RESET})" >&2
    fi
  elif [[ "$ref_type" == "commit" ]]; then
    git -C "$git_dir" worktree add --detach "$root/$dir_name" "$ref" >&2 ||
      die "failed to create worktree"
    echo "Created worktree: ${C_GREEN}${dir_name}${C_RESET} (detached)" >&2
  else
    git -C "$git_dir" worktree add "$root/$dir_name" "$ref" >&2 ||
      die "failed to create worktree"
    echo "Created worktree: ${C_GREEN}${dir_name}${C_RESET} (branch: ${C_CYAN}${ref}${C_RESET})" >&2
  fi

  echo "$root/$dir_name"
}

cmd_list() {
  local root git_dir
  root=$(find_project_root) || return 1
  git_dir="$root/.git"

  # phase 1: parse worktree list
  local -a wt_paths=() wt_heads=() wt_branches=() wt_detached=()
  while IFS='|' read -r path head branch detached; do
    wt_paths+=("$path")
    wt_heads+=("$head")
    wt_branches+=("$branch")
    wt_detached+=("$detached")
  done < <(list_worktrees "$git_dir")

  local count=${#wt_paths[@]}
  if [[ $count -eq 0 ]]; then
    echo "No worktrees found" >&2
    return 1
  fi

  # phase 2: parallel data collection
  local tmpdir
  tmpdir=$(mktemp -d)
  # shellcheck disable=SC2064
  trap "rm -rf '$tmpdir'" RETURN

  for i in "${!wt_paths[@]}"; do
    (
      p="${wt_paths[$i]}"
      log_line=$(git -C "$p" log -1 --format='%h%x09%ar%x09%s' 2>/dev/null) || log_line=$'\t\t'
      status_line=$(git -C "$p" status --porcelain 2>/dev/null | head -1) || status_line=""
      diff_stat=$(git -C "$p" diff --numstat HEAD 2>/dev/null |
        awk '{a+=$1;b+=$2}END{if(a+b>0)printf "+%d-%d",a,b}') || diff_stat=""
      printf '%s\t%s\t%s\n' "$log_line" "$status_line" "$diff_stat"
    ) >"$tmpdir/$i" &
  done
  wait

  # phase 3: build column data
  local real_pwd
  real_pwd=$(pwd -P)

  local -a gutters=() branches=() statuses=() diffs=() paths=() commits=() ages=() messages=()

  for i in "${!wt_paths[@]}"; do
    IFS=$'\t' read -r commit age message status diff_stat <"$tmpdir/$i"

    # gutter
    local real_wt
    real_wt=$(cd "${wt_paths[$i]}" 2>/dev/null && pwd -P) || real_wt="${wt_paths[$i]}"
    if [[ "$real_wt" == "$real_pwd" ]]; then
      gutters+=("@")
    else
      gutters+=(" ")
    fi

    # branch
    if [[ "${wt_detached[$i]}" == "1" ]]; then
      branches+=("(detached)")
    else
      branches+=("${wt_branches[$i]}")
    fi

    # status
    if [[ -n "$status" ]]; then
      statuses+=("M")
    else
      statuses+=("✓")
    fi

    diffs+=("$diff_stat")

    # path relative to root
    local rel="${wt_paths[$i]#"$root"/}"
    if [[ "$real_wt" == "$real_pwd" ]]; then
      paths+=(".")
    else
      paths+=("$rel")
    fi

    commits+=("${wt_heads[$i]:0:8}")
    ages+=("$age")
    messages+=("$message")
  done

  # phase 4: compute widths
  local w_br=6 w_st=6 w_df=5 w_pa=4 w_co=6 w_ag=3
  for i in "${!branches[@]}"; do
    ((${#branches[$i]} > w_br)) && w_br=${#branches[$i]}
    ((${#statuses[$i]} > w_st)) && w_st=${#statuses[$i]}
    ((${#diffs[$i]} > w_df)) && w_df=${#diffs[$i]}
    ((${#paths[$i]} > w_pa)) && w_pa=${#paths[$i]}
    ((${#commits[$i]} > w_co)) && w_co=${#commits[$i]}
    ((${#ages[$i]} > w_ag)) && w_ag=${#ages[$i]}
  done

  # phase 5: render
  printf '  %s  %s  %s  %s  %s  %s  %s\n' \
    "$(pad "${C_BOLD}Branch${C_RESET}" "$w_br")" \
    "$(pad "${C_BOLD}Status${C_RESET}" "$w_st")" \
    "$(pad "${C_BOLD}HEAD±${C_RESET}" "$w_df")" \
    "$(pad "${C_BOLD}Path${C_RESET}" "$w_pa")" \
    "$(pad "${C_BOLD}Commit${C_RESET}" "$w_co")" \
    "$(pad "${C_BOLD}Age${C_RESET}" "$w_ag")" \
    "${C_BOLD}Message${C_RESET}"

  for i in "${!branches[@]}"; do
    # gutter
    local gutter
    if [[ "${gutters[$i]}" == "@" ]]; then
      gutter="${C_BOLD}${C_GREEN}@${C_RESET}"
    else
      gutter=" "
    fi

    # branch
    local br="${C_CYAN}${branches[$i]}${C_RESET}"

    # status
    local st
    if [[ "${statuses[$i]}" == "✓" ]]; then
      st="${C_GREEN}✓${C_RESET}"
    else
      st="${C_YELLOW}M${C_RESET}"
    fi

    # diff stats: color + part green, - part red
    local df=""
    if [[ -n "${diffs[$i]}" ]]; then
      local raw="${diffs[$i]}"
      local plus="${raw%%-*}"
      local minus="${raw#*+}"
      minus="${minus#*-}"
      if [[ -n "$minus" ]]; then
        df="${C_GREEN}${plus}${C_RESET}${C_RED}-${minus}${C_RESET}"
      else
        df="${C_GREEN}${plus}${C_RESET}"
      fi
    fi

    # commit
    local co="${C_YELLOW}${commits[$i]}${C_RESET}"

    # age
    local ag="${C_DIM}${ages[$i]}${C_RESET}"

    printf ' %s %s  %s  %s  %s  %s  %s  %s\n' \
      "$gutter" \
      "$(pad "$br" "$w_br")" \
      "$(pad "$st" "$w_st")" \
      "$(pad "$df" "$w_df")" \
      "$(pad "${paths[$i]}" "$w_pa")" \
      "$(pad "$co" "$w_co")" \
      "$(pad "$ag" "$w_ag")" \
      "${messages[$i]}"
  done

  echo ""
  echo "${C_DIM}○${C_RESET} $count worktree$([[ $count -ne 1 ]] && echo s)"
}

cmd_rm() {
  local root git_dir
  root=$(find_project_root) || return 1
  git_dir="$root/.git"

  local dir_name="" remote=0 force=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
    --remote) remote=1 ;;
    --force) force=1 ;;
    -*) die "unknown option: $1" ;;
    *) dir_name="$1" ;;
    esac
    shift
  done

  [[ -z "$dir_name" ]] && die "usage: wt rm <name> [--remote] [--force]"

  local wt_path="$root/$dir_name"

  # find worktree info
  local wt_branch="" found=0
  while IFS='|' read -r path head branch detached; do
    if [[ "$path" == "$wt_path" ]]; then
      found=1
      wt_branch="$branch"
      break
    fi
  done < <(list_worktrees "$git_dir")

  [[ $found -eq 0 ]] && die "worktree '$dir_name' not found"

  # check dirty
  local dirty=0
  if [[ -n "$(git -C "$wt_path" status --porcelain 2>/dev/null)" ]]; then
    dirty=1
  fi

  if [[ $dirty -eq 1 && $force -eq 0 ]]; then
    die "worktree has uncommitted changes, use --force"
  fi

  # summary
  echo "Remove worktree: ${C_GREEN}${wt_path}${C_RESET}" >&2
  if [[ -n "$wt_branch" ]]; then
    echo "  Branch: ${C_CYAN}${wt_branch}${C_RESET} (will be deleted)" >&2
    if [[ $remote -eq 1 ]]; then
      echo "  Remote: ${C_CYAN}origin/${wt_branch}${C_RESET} (will be deleted)" >&2
    fi
  else
    echo "  Detached (no branch to delete)" >&2
  fi
  if [[ $dirty -eq 1 ]]; then
    echo "  ${C_YELLOW}⚠${C_RESET} worktree has uncommitted changes" >&2
  fi

  # confirm
  local confirm
  read -r -p "Confirm? [y/N] " confirm || {
    echo "error: cannot read confirmation" >&2
    return 1
  }
  if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "Aborted" >&2
    return 0
  fi

  # remove
  local rm_flags=()
  [[ $force -eq 1 ]] && rm_flags+=(--force)
  git -C "$git_dir" worktree remove "${rm_flags[@]}" "$wt_path" ||
    die "failed to remove worktree"
  git -C "$git_dir" worktree prune

  echo "Removed worktree: ${C_GREEN}${dir_name}${C_RESET}" >&2

  if [[ -n "$wt_branch" ]]; then
    git -C "$git_dir" branch -D "$wt_branch" 2>/dev/null
    echo "Deleted branch: ${C_CYAN}${wt_branch}${C_RESET}" >&2

    if [[ $remote -eq 1 ]]; then
      git -C "$git_dir" push origin --delete "$wt_branch" ||
        echo "warning: failed to delete remote branch" >&2
      echo "Deleted remote branch: ${C_CYAN}origin/${wt_branch}${C_RESET}" >&2
    fi
  fi
}

# ── Main ───────────────────────────────────────────────────────────────

main() {
  local cmd="${1:-help}"
  shift 2>/dev/null || true
  case "$cmd" in
  clone) cmd_clone "$@" ;;
  switch) cmd_switch "$@" ;;
  list) cmd_list "$@" ;;
  rm) cmd_rm "$@" ;;
  help | --help | -h) cmd_help ;;
  *) die "unknown command: $cmd (see: wt help)" ;;
  esac
}

main "$@"



