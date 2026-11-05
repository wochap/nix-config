#!/usr/bin/env bash

# Recursively search for Nix 'result*' symlinks under a path that point to /nix/store,
# and interactively prompts using gum to select which ones to delete.
# Releasing these symlinks unregisters them as GC roots so nix-collect-garbage can reclaim store space.

set -euo pipefail

usage() {
  cat <<EOF
Usage: nix-clean-results [OPTIONS] [PATH]

Recursively find Nix 'result*' symlinks under PATH (default: .) that point to
/nix/store, and interactively select which ones to delete to release GC roots.

By default, prompts interactively using gum to select which result links to delete.
Use --yes to delete all without prompting, or --dry-run to only inspect.

Options:
  -y, --yes          delete without interactive prompt
  -d, --dry-run      only inspect and list result symlinks (dry run)
  -g, --gc           run 'nix-collect-garbage' after deleting symlinks
  -f, --flake-only   only match repositories or directories containing flake.nix
  -h, --help         show this help message
EOF
}

APPLY_ALL=0
DRY_RUN=0
RUN_GC=0
FLAKE_ONLY=0
ROOT="."

while [[ $# -gt 0 ]]; do
  case "$1" in
  -y | --yes) APPLY_ALL=1 ;;
  -d | --dry-run) DRY_RUN=1 ;;
  -g | --gc) RUN_GC=1 ;;
  -f | --flake-only) FLAKE_ONLY=1 ;;
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
  C_MAGENTA="\033[0;35m"
else
  C_RESET=""
  C_BOLD=""
  C_DIM=""
  C_GREEN=""
  C_YELLOW=""
  C_BLUE=""
  C_CYAN=""
  C_RED=""
  C_MAGENTA=""
fi

echo -e "${C_BOLD}Scanning for Nix result symlinks in:${C_RESET} $ROOT"
if ((FLAKE_ONLY)); then
  echo -e "${C_DIM}Filter: only directories/repositories with flake.nix${C_RESET}"
fi
echo

# Find all symlinks matching 'result*' while skipping heavy ignored directories
mapfile -d '' FOUND_LINKS < <(
  find "$ROOT" \
    \( -name .direnv -o -name node_modules -o -name .git -o -name .cache -o -name target -o -name build -o -name dist \) -prune \
    -o -type l -name "result*" -print0 2>/dev/null
)

candidate_links=()
declare -A link_targets=()
declare -A link_relpaths=()
declare -A link_sizes=()

# Filter links pointing into /nix/store
for link in "${FOUND_LINKS[@]}"; do
  target=$(readlink "$link" 2>/dev/null || true)
  if [[ -z "$target" || "$target" != /nix/store/* ]]; then
    continue
  fi

  parent_dir=$(dirname "$link")

  if ((FLAKE_ONLY)); then
    # Check if directory or parent git repo contains a flake.nix
    has_flake=0
    if [[ -f "$parent_dir/flake.nix" ]]; then
      has_flake=1
    else
      git_root=$(git -C "$parent_dir" rev-parse --show-toplevel 2>/dev/null || true)
      if [[ -n "$git_root" && -f "$git_root/flake.nix" ]]; then
        has_flake=1
      fi
    fi

    if ((!has_flake)); then
      continue
    fi
  fi

  # Compute readable relative path
  rel_path="$link"
  if [[ "$ROOT" == "." ]]; then
    rel_path="./${link#./}"
  fi

  candidate_links+=("$link")
  link_targets["$link"]="$target"
  link_relpaths["$link"]="$rel_path"
done

if ((${#candidate_links[@]} == 0)); then
  echo -e "${C_GREEN}No result symlinks found under $ROOT.${C_RESET}"
  exit 0
fi

echo -e "Found ${C_BOLD}${#candidate_links[@]}${C_RESET} result symlink(s). Querying store closure sizes..."

# Separate valid targets from dangling/broken targets
valid_targets=()
declare -A store_closure_sizes=()

for l in "${candidate_links[@]}"; do
  target="${link_targets[$l]}"
  if [[ -e "$target" ]]; then
    valid_targets+=("$target")
  else
    link_sizes["$l"]="broken link"
  fi
done

if ((${#valid_targets[@]} > 0)) && command -v nix >/dev/null 2>&1; then
  while IFS=$'\t' read -r path size; do
    if [[ -n "$path" && -n "$size" ]]; then
      store_closure_sizes["$path"]="$size"
    fi
  done < <(nix path-info -Sh "${valid_targets[@]}" 2>/dev/null | awk '{path=$1; $1=""; sub(/^[ \t]+/, ""); print path "\t" $0}' || true)
fi

for l in "${candidate_links[@]}"; do
  if [[ "${link_sizes[$l]:-}" == "broken link" ]]; then
    continue
  fi
  target="${link_targets[$l]}"
  sz="${store_closure_sizes[$target]:-unknown size}"
  link_sizes["$l"]="$sz"
done

selected_links=()
list_deleted=()
list_would_delete=()
list_skipped=()
interactive_prompted=0

if ((DRY_RUN)); then
  echo
  echo -e "${C_YELLOW}Dry run mode: the following symlinks would be deleted:${C_RESET}"
  for l in "${candidate_links[@]}"; do
    rel="${link_relpaths[$l]}"
    tgt=$(basename "${link_targets[$l]}")
    sz="${link_sizes[$l]}"
    printf "  ${C_CYAN}%s${C_RESET} -> %s ${C_DIM}(Closure: %s)${C_RESET}\n" "$rel" "$tgt" "$sz"
    list_would_delete+=("$rel ($tgt, $sz)")
  done
elif ((APPLY_ALL)); then
  selected_links=("${candidate_links[@]}")
elif [[ -t 0 && -t 1 ]] && command -v gum >/dev/null 2>&1; then
  interactive_prompted=1
  choose_options=()
  for l in "${candidate_links[@]}"; do
    rel="${link_relpaths[$l]}"
    tgt=$(basename "${link_targets[$l]}")
    sz="${link_sizes[$l]}"
    choose_options+=("$rel -> $tgt ($sz)|$l")
  done

  echo
  echo -e "${C_BOLD}Select Nix result symlinks to delete:${C_RESET}"
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
    echo -e "${C_YELLOW}Aborted by user. No symlinks were deleted.${C_RESET}"
    selected_links=()
  else
    mapfile -t selected_links < <(echo "$gum_selected" | sed '/^[[:space:]]*$/d')
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
  for l in "${candidate_links[@]}"; do
    rel="${link_relpaths[$l]}"
    tgt=$(basename "${link_targets[$l]}")
    sz="${link_sizes[$l]}"
    list_would_delete+=("$rel ($tgt, $sz)")
  done
fi

if ((APPLY_ALL)) || ((interactive_prompted)); then
  declare -A is_selected=()
  for l in "${selected_links[@]}"; do
    is_selected["$l"]=1
  done

  if ((${#selected_links[@]} > 0)); then
    echo
    echo -e "${C_BOLD}=== Deleting Selected Symlinks ===${C_RESET}"
  fi

  for l in "${candidate_links[@]}"; do
    rel="${link_relpaths[$l]}"
    tgt=$(basename "${link_targets[$l]}")
    sz="${link_sizes[$l]}"

    if [[ -n "${is_selected[$l]:-}" ]]; then
      if rm -f "$l"; then
        list_deleted+=("$rel ($tgt, $sz)")
        printf "${C_GREEN}[DELETED]${C_RESET}        %s ${C_DIM}-> %s (%s)${C_RESET}\n" "$rel" "$tgt" "$sz"
      else
        printf "${C_RED}[FAILED]${C_RESET}         %s ${C_DIM}(permission or I/O error)${C_RESET}\n" "$rel"
      fi
    else
      list_skipped+=("$rel ($tgt, $sz)")
    fi
  done
fi

echo
echo -e "${C_BOLD}=== Summary ===${C_RESET}"

if ((${#list_deleted[@]} > 0)); then
  printf "${C_GREEN}Deleted symlinks (%d):${C_RESET}\n" "${#list_deleted[@]}"
  for item in "${list_deleted[@]}"; do
    echo "  ✓ $item"
  done
fi

if ((${#list_would_delete[@]} > 0)); then
  printf "${C_YELLOW}Would delete (%d):${C_RESET}\n" "${#list_would_delete[@]}"
  for item in "${list_would_delete[@]}"; do
    echo "  • $item"
  done
fi

if ((${#list_skipped[@]} > 0)); then
  printf "${C_DIM}Skipped (unselected) (%d):${C_RESET}\n" "${#list_skipped[@]}"
  for item in "${list_skipped[@]}"; do
    echo "  - $item"
  done
fi

if ((${#list_deleted[@]} > 0)); then
  echo
  echo -e "${C_CYAN}Tip:${C_RESET} The GC roots have been freed. Run ${C_BOLD}nix-collect-garbage -d${C_RESET} to reclaim disk space."

  if ((RUN_GC)); then
    echo
    echo -e "${C_BOLD}Running nix-collect-garbage...${C_RESET}"
    nix-collect-garbage
  fi
fi
