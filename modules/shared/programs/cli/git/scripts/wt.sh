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
  local visible="$str"
  local esc=$'\e['
  while [[ "$visible" == *"$esc"* ]]; do
    local before="${visible%%"$esc"*}"
    local after="${visible#*"$esc"}"
    after="${after#*m}"
    visible="${before}${after}"
  done
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

verify_same_repo() {
  local target_dir="$1" source_dir="$2"
  local -a target_roots=() source_roots=()
  while IFS= read -r sha; do
    target_roots+=("$sha")
  done < <(git -C "$target_dir" rev-list --max-parents=0 HEAD 2>/dev/null | sort)
  while IFS= read -r sha; do
    source_roots+=("$sha")
  done < <(git -C "$source_dir" rev-list --max-parents=0 HEAD 2>/dev/null | sort)
  for s in "${source_roots[@]}"; do
    for t in "${target_roots[@]}"; do
      [[ "$s" == "$t" ]] && return 0
    done
  done
  return 1
}

find_common_ancestor() {
  local source_dir="$1"
  while IFS= read -r sha; do
    if git cat-file -e "$sha" 2>/dev/null; then
      echo "$sha"
      return 0
    fi
  done < <(git -C "$source_dir" rev-list HEAD 2>/dev/null)
  return 1
}

resolve_pull_source() {
  local root="$1" git_dir="$2" arg="$3"

  # try as worktree folder name in current project (only if inside a wt project)
  if [[ -n "$root" && -n "$git_dir" ]]; then
    local candidate="$root/$arg"
    if [[ -d "$candidate" ]] && find_worktree_by_path "$git_dir" "$candidate"; then
      echo "$candidate"
      return 0
    fi
  fi

  # fall back to filesystem path
  if [[ -d "$arg" ]]; then
    local resolved
    resolved=$(cd "$arg" && pwd -P) || die "cannot resolve path: $arg"
    git -C "$resolved" rev-parse --git-dir &>/dev/null ||
      die "not a git repository: $arg"
    echo "$resolved"
    return 0
  fi

  die "source not found: $arg (not a worktree name or valid path)"
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
  wt pull <source> [--staged]       Pull changes from worktree/repo
  wt doctor                         Repair broken worktree links
  wt rename <new-name>              Rename current worktree directory

Options:
  --remote    Also delete remote branch (rm)
  --force     Allow removing dirty worktree (rm)
  --staged    Pull only staged changes from source (pull)

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

  git -C "$git_dir" config remote.origin.fetch \
    '+refs/heads/*:refs/remotes/origin/*' ||
    die "failed to configure remote tracking"

  git -C "$git_dir" fetch origin >&2 ||
    die "failed to configure remote tracking"

  git -C "$git_dir" branch \
    --set-upstream-to="origin/$default_branch" \
    "$default_branch" >&2 ||
    die "failed to configure upstream"

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
  local -a positionals=()
  while [[ $# -gt 0 ]]; do
    case "$1" in
    -b) new_branch=1 ;;
    -*) die "unknown option: $1" ;;
    *) positionals+=("$1") ;;
    esac
    shift
  done

  local ref="${positionals[0]:-}" arg2="${positionals[1]:-}"

  # ── -b mode: new branch + worktree ──
  if [[ $new_branch -eq 1 ]]; then
    [[ -z "$ref" ]] && die "usage: wt switch -b <branch> [from]"
    local branch="$ref"
    local from="${arg2:-HEAD}"
    local dir_name="${branch//\//-}"

    # default base: current worktree's HEAD when inside one (bare repo HEAD
    # always points at the default branch, never at the worktree we're in)
    if [[ -z "$arg2" ]]; then
      local cur_top
      cur_top=$(git rev-parse --show-toplevel 2>/dev/null) || cur_top=""
      if [[ -n "$cur_top" ]]; then
        cur_top=$(cd "$cur_top" && pwd -P)
        if find_worktree_by_path "$git_dir" "$cur_top"; then
          from=$(git -C "$cur_top" rev-parse HEAD) ||
            die "cannot resolve HEAD of worktree '${cur_top#"$root"/}'"
        fi
      fi
    fi

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
  printf ' %s %s  %s  %s  %s  %s  %s  %s\n' \
    " " \
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

cmd_doctor() {
  local root git_dir
  root=$(find_project_root) || return 1
  git_dir="$root/.git"

  local -a wt_dirs=()
  for d in "$root"/*/; do
    [[ -f "${d}.git" ]] && wt_dirs+=("${d%/}")
  done

  local count=${#wt_dirs[@]}
  if [[ $count -eq 0 ]]; then
    echo "No worktrees found" >&2
    return 1
  fi

  local repaired=0
  for p in "${wt_dirs[@]}"; do
    local rel="${p#"$root"/}"
    local output
    output=$(git -C "$git_dir" worktree repair "$p" 2>&1)
    if [[ -n "$output" ]]; then
      echo "$output" >&2
      echo "  ${C_GREEN}repaired${C_RESET} ${rel}" >&2
      ((repaired++))
    else
      echo "  ${C_GREEN}✓${C_RESET} ${rel}" >&2
    fi
  done

  echo "" >&2
  if [[ $repaired -gt 0 ]]; then
    echo "${C_GREEN}Repaired $repaired worktree$([[ $repaired -ne 1 ]] && echo s)${C_RESET}" >&2
  else
    echo "${C_DIM}All $count worktrees healthy${C_RESET}" >&2
  fi
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

cmd_pull() {
  local staged=0 source_arg=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
    --staged) staged=1 ;;
    -*) die "unknown option: $1" ;;
    *) source_arg="$1" ;;
    esac
    shift
  done

  [[ -z "$source_arg" ]] && die "usage: wt pull <source> [--staged]"

  # detect target context
  local in_git_repo=0
  if git rev-parse --git-dir &>/dev/null; then
    in_git_repo=1
  fi

  if [[ $in_git_repo -eq 0 && $staged -eq 0 ]]; then
    die "default mode requires a git repository as target (use --staged for non-repo directories)"
  fi

  # optionally detect wt project for folder-name source resolution
  local root="" git_dir=""
  if [[ $in_git_repo -eq 1 ]]; then
    root=$(find_project_root 2>/dev/null) || root=""
    if [[ -n "$root" ]]; then
      git_dir="$root/.git"
    fi
  fi

  local source_path
  source_path=$(resolve_pull_source "$root" "$git_dir" "$source_arg") || return 1

  # same-repo verification (only when target is a git repo)
  if [[ $in_git_repo -eq 1 ]]; then
    verify_same_repo "." "$source_path" ||
      die "source and target are not the same repository"
  fi

  # dirty target check (only when target is a git repo)
  if [[ $in_git_repo -eq 1 && -n "$(git status --porcelain 2>/dev/null)" ]]; then
    echo "${C_YELLOW}warning: target has uncommitted changes${C_RESET}" >&2
    local confirm
    read -r -p "Continue? [y/N] " confirm || return 1
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
      echo "Aborted" >&2
      return 0
    fi
  fi

  # --staged mode: always patch (works in any directory)
  if [[ $staged -eq 1 ]]; then
    local patch
    patch=$(git -C "$source_path" diff --cached) || die "failed to get staged diff from source"
    [[ -z "$patch" ]] && die "nothing staged in source"
    echo "$patch" | git apply >&2 || die "patch apply failed"
    echo "${C_GREEN}Applied staged changes from ${source_path##*/}${C_RESET}" >&2
    return 0
  fi

  # default mode: detect same-project vs cross-clone
  local target_common source_common
  target_common=$(git rev-parse --git-common-dir 2>/dev/null | xargs realpath 2>/dev/null || git rev-parse --git-common-dir)
  source_common=$(git -C "$source_path" rev-parse --git-common-dir 2>/dev/null | xargs realpath 2>/dev/null || git -C "$source_path" rev-parse --git-common-dir)

  if [[ "$target_common" == "$source_common" ]]; then
    # same project: native squash merge
    local source_sha
    source_sha=$(git -C "$source_path" rev-parse HEAD) || die "cannot resolve source HEAD"
    git merge --squash "$source_sha" >&2 || {
      echo "${C_RED}Merge produced conflicts — resolve manually${C_RESET}" >&2
      return 1
    }
    echo "${C_GREEN}Squashed changes from ${source_path##*/} — staged, ready to commit${C_RESET}" >&2
  else
    # cross-clone: patch via common ancestor walk
    local base
    base=$(find_common_ancestor "$source_path") ||
      die "no common ancestor found between source and target"
    git -C "$source_path" diff "$base"..HEAD | git apply >&2 ||
      die "patch apply failed"
    echo "${C_GREEN}Applied changes from ${source_path##*/}${C_RESET}" >&2
  fi
}

cmd_rename() {
  local root git_dir
  root=$(find_project_root) || return 1
  git_dir="$root/.git"

  local new_name=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
    -*) die "unknown option: $1" ;;
    *) new_name="$1" ;;
    esac
    shift
  done

  [[ -z "$new_name" ]] && die "usage: wt rename <new-name>"
  case "$new_name" in
  */*) die "invalid name: '$new_name' (cannot contain '/')" ;;
  . | ..) die "invalid name: '$new_name'" ;;
  esac

  local wt_path
  wt_path=$(git rev-parse --show-toplevel 2>/dev/null) ||
    die "rename must be run from inside a worktree"
  find_worktree_by_path "$git_dir" "$wt_path" ||
    die "'${wt_path#"$root"/}' is not a registered worktree of this project"

  local old_name="${wt_path##*/}"
  if [[ "$new_name" == "$old_name" ]]; then
    echo "$wt_path"
    return 0
  fi

  if [[ -d "$root/$new_name" ]]; then
    die "directory '$new_name' already exists"
  fi

  git -C "$git_dir" worktree move "$wt_path" "$root/$new_name" ||
    die "failed to rename worktree"

  echo "Renamed worktree: ${C_GREEN}${old_name}${C_RESET} to ${C_GREEN}${new_name}${C_RESET}" >&2
  echo "$root/$new_name"
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
  pull) cmd_pull "$@" ;;
  doctor) cmd_doctor "$@" ;;
  rename) cmd_rename "$@" ;;
  help | --help | -h) cmd_help ;;
  *) die "unknown command: $cmd (see: wt help)" ;;
  esac
}

main "$@"

