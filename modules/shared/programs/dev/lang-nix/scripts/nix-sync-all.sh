#!/usr/bin/env bash

# Recursively search for Git repositories under a path that contain a flake.nix,
# and updates their inputs.nixpkgs.url to match the nixpkgs commit from flake.nix:4.
# Dry run by default: lists repositories and planned changes without modifying files.

set -euo pipefail

usage() {
  cat <<EOF
Usage: nix-sync-all [OPTIONS] [PATH]

Recursively find git repositories with flake.nix under PATH (default: .)
and update inputs.nixpkgs.url to match the nixpkgs commit in flake.nix (line 4).

By default, prompts interactively using gum to select which repositories to update.
Use --yes to update all without prompting, or --dry-run to only inspect.

Options:
  -y, --yes          actually update flake.nix files without prompt (default: interactive selection)
  -d, --dry-run      only inspect repositories and report changes (dry run)
  -s, --source FILE  path to source flake.nix (default: auto-detected from nix-config)
  -l, --line LINE    explicit line to use for nixpkgs.url
  -u, --url URL      explicit URL to use for nixpkgs.url
  -f, --force        allow updating even if repository has uncommitted changes
  -h, --help         show this help message
EOF
}

APPLY_ALL=0
DRY_RUN=0
SOURCE_ARG=""
CUSTOM_LINE=""
CUSTOM_URL=""
ALLOW_DIRTY=0
ROOT="."

while [[ $# -gt 0 ]]; do
  case "$1" in
  -y | --yes) APPLY_ALL=1 ;;
  -d | --dry-run) DRY_RUN=1 ;;
  -s | --source)
    SOURCE_ARG="${2:?--source requires a file path}"
    shift
    ;;
  -l | --line)
    CUSTOM_LINE="${2:?--line requires a line argument}"
    shift
    ;;
  -u | --url)
    CUSTOM_URL="${2:?--url requires a URL argument}"
    shift
    ;;
  -f | --force) ALLOW_DIRTY=1 ;;
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

if ((APPLY_ALL && DRY_RUN)); then
  echo "error: --yes and --dry-run cannot be used together" >&2
  exit 1
fi

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

# Determine target nixpkgs line
TARGET_LINE=""
SOURCE_FLAKE=""

if [[ -n "$CUSTOM_LINE" ]]; then
  TARGET_LINE="$CUSTOM_LINE"
elif [[ -n "$CUSTOM_URL" ]]; then
  TARGET_LINE="nixpkgs.url = \"${CUSTOM_URL}\";"
else
  SOURCE_CANDIDATES=()
  if [[ -n "$SOURCE_ARG" ]]; then
    SOURCE_CANDIDATES+=("${SOURCE_ARG/#\~/$HOME}")
  fi
  if [[ -n "${NIX_CONFIG_DIR:-}" ]]; then
    SOURCE_CANDIDATES+=("${NIX_CONFIG_DIR}/flake.nix")
  fi
  SOURCE_CANDIDATES+=(
    "$HOME/nix-config/flake.nix"
    "/home/gean/nix-config/flake.nix"
    "/etc/nixos/flake.nix"
    "$HOME/.config/nixos/flake.nix"
    "./flake.nix"
  )

  for candidate in "${SOURCE_CANDIDATES[@]}"; do
    if [[ -f "$candidate" ]]; then
      SOURCE_FLAKE="$candidate"
      break
    fi
  done

  if [[ -n "$SOURCE_FLAKE" ]]; then
    line4=$(sed -n '4p' "$SOURCE_FLAKE" 2>/dev/null || true)
    if [[ "$line4" =~ nixpkgs\.url ]]; then
      TARGET_LINE="$line4"
    else
      # Fallback to first line assigning nixpkgs.url in the source flake
      found_line=$(grep -m1 -E '^[[:space:]]*nixpkgs\.url[[:space:]]*=' "$SOURCE_FLAKE" 2>/dev/null || true)
      if [[ -n "$found_line" ]]; then
        TARGET_LINE="$found_line"
      fi
    fi
  fi

  # Ultimate fallback to known commit if no source flake was located
  if [[ -z "$TARGET_LINE" ]]; then
    TARGET_LINE='    nixpkgs.url = "github:nixos/nixpkgs/1f607aa79b6356ed45d3cd3c8079c196e79efa2c"; # nixos-26.05 (26 oct 2026)'
  fi
fi

# Clean leading whitespace and strip optional inputs. prefix from core assignment
CLEAN_TARGET="$(echo "$TARGET_LINE" | sed -e 's/^[[:space:]]*//')"
CORE_ASSIGNMENT="${CLEAN_TARGET#inputs.}"

echo -e "${C_BOLD}Target nixpkgs line:${C_RESET}"
echo "  $CLEAN_TARGET"
if [[ -n "$SOURCE_FLAKE" ]]; then
  echo -e "${C_DIM}Source: $SOURCE_FLAKE${C_RESET}"
fi
echo

# Find all .git directories/files while skipping common heavy caches and dependencies
mapfile -d '' GIT_ENTRIES < <(
  find "$ROOT" \
    \( -name .direnv -o -name node_modules -o -name target -o -name .cache -o -name dist -o -name build \) -prune \
    -o -name .git -prune -print0 2>/dev/null
)

list_succeeded=()
list_would_update=()
list_skipped_unselected=()
list_skipped_uptodate=()
list_skipped_dirty=()
list_skipped_other=()
list_failed=()

candidate_repos=()
declare -A candidate_flake=()
declare -A candidate_linenum=()
declare -A candidate_oldline=()
declare -A candidate_newline=()

for git_entry in "${GIT_ENTRIES[@]}"; do
  repo_dir=$(dirname "$git_entry")
  repo_dir="${repo_dir%/}"
  if [[ "$repo_dir" == "." || "$repo_dir" == "./." ]]; then
    repo_dir="."
  elif [[ "$repo_dir" != /* ]]; then
    repo_dir="./${repo_dir#./}"
  fi

  target_flake="$repo_dir/flake.nix"
  if [[ ! -f "$target_flake" ]]; then
    continue
  fi

  # Skip if this is the source flake itself
  if [[ -n "$SOURCE_FLAKE" && -f "$SOURCE_FLAKE" ]]; then
    target_real=$(realpath "$target_flake" 2>/dev/null || echo "")
    source_real=$(realpath "$SOURCE_FLAKE" 2>/dev/null || echo "")
    if [[ -n "$target_real" && "$target_real" == "$source_real" ]]; then
      list_skipped_other+=("$repo_dir (source repository)")
      printf "${C_CYAN}[SOURCE REPO]${C_RESET}       %s ${C_DIM}(source of nixpkgs.url)${C_RESET}\n" "$repo_dir"
      continue
    fi
  fi

  # Check if working tree is clean
  status_porcelain=$(git -C "$repo_dir" status --porcelain 2>/dev/null || true)
  if [[ -n "$status_porcelain" && $ALLOW_DIRTY -eq 0 ]]; then
    changed_count=$(echo "$status_porcelain" | wc -l | tr -d ' ')
    list_skipped_dirty+=("$repo_dir ($changed_count uncommitted change(s))")
    printf "${C_YELLOW}[SKIPPED - DIRTY]${C_RESET}  %s ${C_DIM}(%s uncommitted changes)${C_RESET}\n" "$repo_dir" "$changed_count"
    continue
  fi

  # Locate inputs.nixpkgs.url or nixpkgs.url line in flake.nix
  matching_line=$(grep -n -m1 -E '^[[:space:]]*(inputs\.)?nixpkgs\.url[[:space:]]*=' "$target_flake" 2>/dev/null || true)
  if [[ -z "$matching_line" ]]; then
    list_skipped_other+=("$repo_dir (no nixpkgs.url entry in flake.nix)")
    printf "${C_YELLOW}[SKIPPED - NO MATCH]${C_RESET} %s ${C_DIM}(no nixpkgs.url in flake.nix)${C_RESET}\n" "$repo_dir"
    continue
  fi

  line_num="${matching_line%%:*}"
  current_line="${matching_line#*:}"

  # Extract indentation of existing line
  if [[ "$current_line" =~ ^([[:space:]]*) ]]; then
    indent="${BASH_REMATCH[1]}"
  else
    indent=""
  fi

  # Preserve inputs. prefix if the target file used it
  prefix=""
  if [[ "$current_line" =~ ^[[:space:]]*(inputs\.) ]]; then
    prefix="${BASH_REMATCH[1]}"
  fi

  new_line="${indent}${prefix}${CORE_ASSIGNMENT}"

  # Check if already up to date
  if [[ "$current_line" == "$new_line" ]]; then
    list_skipped_uptodate+=("$repo_dir")
    printf "${C_CYAN}[UP TO DATE]${C_RESET}       %s\n" "$repo_dir"
    continue
  fi

  candidate_repos+=("$repo_dir")
  candidate_flake["$repo_dir"]="$target_flake"
  candidate_linenum["$repo_dir"]="$line_num"
  candidate_oldline["$repo_dir"]="$current_line"
  candidate_newline["$repo_dir"]="$new_line"

  if ((DRY_RUN)); then
    printf "${C_GREEN}[WOULD UPDATE]${C_RESET}     %s\n" "$repo_dir"
    printf "  ${C_DIM}old:${C_RESET} %s\n" "$current_line"
    printf "  ${C_DIM}new:${C_RESET} %s\n" "$new_line"
  else
    printf "${C_GREEN}[UPDATE AVAILABLE]${C_RESET} %s\n" "$repo_dir"
    printf "  ${C_DIM}old:${C_RESET} %s\n" "$current_line"
    printf "  ${C_DIM}new:${C_RESET} %s\n" "$new_line"
  fi
done

interactive_prompted=0
selected_repos=()

if ((${#candidate_repos[@]} > 0)); then
  if ((DRY_RUN)); then
    for r in "${candidate_repos[@]}"; do
      list_would_update+=("$r")
    done
  elif ((APPLY_ALL)); then
    selected_repos=("${candidate_repos[@]}")
  elif [[ -t 0 && -t 1 ]] && command -v gum >/dev/null 2>&1; then
    interactive_prompted=1
    choose_options=()
    for r in "${candidate_repos[@]}"; do
      choose_options+=("$r|$r")
    done

    echo
    echo -e "${C_BOLD}Select repositories to update:${C_RESET}"
    set +e
    gum_selected=$(gum choose \
      --no-limit \
      --selected="*" \
      --label-delimiter="|" \
      --header="Space to toggle, Enter to confirm, Esc to abort" \
      "${choose_options[@]}" < /dev/tty)
    gum_status=$?
    set -e

    if ((gum_status != 0)); then
      echo -e "${C_YELLOW}Update aborted by user.${C_RESET}"
      selected_repos=()
    else
      mapfile -t selected_repos < <(echo "$gum_selected" | sed '/^[[:space:]]*$/d')
    fi
  else
    # Non-interactive terminal or gum not available without --yes
    if ! command -v gum >/dev/null 2>&1; then
      echo
      echo -e "${C_YELLOW}Note:${C_RESET} 'gum' is not installed. Skipping interactive selection."
      echo -e "      Run with ${C_BOLD}--yes${C_RESET} to apply changes, or install gum."
    else
      echo
      echo -e "${C_YELLOW}Note:${C_RESET} Non-interactive terminal detected. Skipping interactive selection."
      echo -e "      Run with ${C_BOLD}--yes${C_RESET} to apply changes."
    fi
    for r in "${candidate_repos[@]}"; do
      list_would_update+=("$r")
    done
  fi

  if ((APPLY_ALL)) || ((interactive_prompted)); then
    declare -A is_selected=()
    for r in "${selected_repos[@]}"; do
      is_selected["$r"]=1
    done

    if ((${#selected_repos[@]} > 0)); then
      echo
      echo -e "${C_BOLD}=== Updating Selected Repositories ===${C_RESET}"
    fi

    for repo_dir in "${candidate_repos[@]}"; do
      if [[ -n "${is_selected[$repo_dir]:-}" ]]; then
        target_flake="${candidate_flake[$repo_dir]}"
        line_num="${candidate_linenum[$repo_dir]}"
        new_line="${candidate_newline[$repo_dir]}"
        current_line="${candidate_oldline[$repo_dir]}"

        temp_file=$(mktemp "${repo_dir}/flake.nix.tmp.XXXXXX" 2>/dev/null || mktemp "/tmp/flake.nix.tmp.XXXXXX")
        if awk -v n="$line_num" -v s="$new_line" 'NR == n { print s; next } { print }' "$target_flake" > "$temp_file" && mv "$temp_file" "$target_flake"; then
          list_succeeded+=("$repo_dir")
          printf "${C_GREEN}[UPDATED]${C_RESET}          %s\n" "$repo_dir"
          printf "  ${C_DIM}old:${C_RESET} %s\n" "$current_line"
          printf "  ${C_DIM}new:${C_RESET} %s\n" "$new_line"
        else
          rm -f "$temp_file"
          list_failed+=("$repo_dir (failed to write flake.nix)")
          printf "${C_RED}[FAILED]${C_RESET}           %s ${C_DIM}(write error)${C_RESET}\n" "$repo_dir"
        fi
      else
        list_skipped_unselected+=("$repo_dir")
      fi
    done
  fi
fi

echo
echo -e "${C_BOLD}=== Summary ===${C_RESET}"

if ((${#list_succeeded[@]} > 0)); then
  printf "${C_GREEN}Successfully updated (%d):${C_RESET}\n" "${#list_succeeded[@]}"
  for item in "${list_succeeded[@]}"; do
    echo "  ✓ $item"
  done
fi

if ((${#list_would_update[@]} > 0)); then
  printf "${C_GREEN}Would update (%d):${C_RESET}\n" "${#list_would_update[@]}"
  for item in "${list_would_update[@]}"; do
    echo "  ➜ $item"
  done
fi

if ((${#list_skipped_unselected[@]} > 0)); then
  printf "${C_YELLOW}Skipped - not selected (%d):${C_RESET}\n" "${#list_skipped_unselected[@]}"
  for item in "${list_skipped_unselected[@]}"; do
    echo "  - $item"
  done
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

total_matched=$(( ${#candidate_repos[@]} + ${#list_skipped_uptodate[@]} + ${#list_skipped_dirty[@]} + ${#list_skipped_other[@]} + ${#list_failed[@]} ))
total_skipped=$(( ${#list_skipped_uptodate[@]} + ${#list_skipped_dirty[@]} + ${#list_skipped_other[@]} + ${#list_skipped_unselected[@]} ))
echo
if ((total_matched == 0)); then
  echo "No git repositories with flake.nix found under $ROOT."
else
  if ((DRY_RUN)) || ((!APPLY_ALL && ${#selected_repos[@]} == 0 && ${#candidate_repos[@]} > 0 && !interactive_prompted)); then
    echo -e "${C_BOLD}Total:${C_RESET} $total_matched matching repo(s) (${#list_would_update[@]} to update, $total_skipped skipped, ${#list_failed[@]} failed)"
    if ((${#list_would_update[@]} > 0)); then
      echo -e "${C_YELLOW}Dry run complete.${C_RESET} Run without ${C_BOLD}--dry-run${C_RESET} to select repositories or with ${C_BOLD}--yes${C_RESET} to apply all."
    fi
  else
    echo -e "${C_BOLD}Total:${C_RESET} $total_matched matching repo(s) (${#list_succeeded[@]} updated, $total_skipped skipped, ${#list_failed[@]} failed)"
  fi
fi
