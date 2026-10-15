#!/usr/bin/env bash

# Recursively find Rust build artifacts (target/ next to a Cargo.toml) under a
# path and clean them. Dry run by default: lists size + last build date.

set -euo pipefail

usage() {
  cat <<EOF
Usage: cargo-clean-all [OPTIONS] [PATH]

Find every target/ dir next to a Cargo.toml under PATH (default: .) and clean it.
Without --yes it only lists what would be cleaned.

Options:
  -y, --yes            actually clean (default: dry run)
  -o, --older-than N   only targets not modified in the last N days
  -r, --rm             rm -rf target/ instead of running cargo clean
  -h, --help           show this help
EOF
}

APPLY=0
OLDER_THAN=""
USE_RM=0
ROOT="."

while [[ $# -gt 0 ]]; do
  case "$1" in
  -y | --yes) APPLY=1 ;;
  -o | --older-than)
    OLDER_THAN="${2:?--older-than needs a number of days}"
    shift
    ;;
  -r | --rm) USE_RM=1 ;;
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

if [[ ! -d "$ROOT" ]]; then
  echo "not a directory: $ROOT" >&2
  exit 1
fi

if [[ -n "$OLDER_THAN" && ! "$OLDER_THAN" =~ ^[0-9]+$ ]]; then
  echo "--older-than must be a number of days" >&2
  exit 1
fi

# Don't descend into target/, .git or node_modules
mapfile -d '' TARGETS < <(
  find "$ROOT" \( -name .git -o -name node_modules \) -prune -o \
    -type d -name target -prune -print0 2>/dev/null
)

total_kb=0
count=0
now=$(date +%s)

for t in "${TARGETS[@]}"; do
  project=$(dirname "$t")
  [[ -f "$project/Cargo.toml" ]] || continue

  mtime=$(stat -c %Y "$t")
  if [[ -n "$OLDER_THAN" ]] && ((now - mtime < OLDER_THAN * 86400)); then
    continue
  fi

  kb=$(du -sk "$t" | cut -f1)
  total_kb=$((total_kb + kb))
  count=$((count + 1))

  printf '%8s  %s  %s\n' "$(numfmt --to=iec --from-unit=1024 "$kb")" \
    "$(date -d "@$mtime" +%F)" "$t"

  if ((APPLY)); then
    if ((USE_RM)); then
      rm -rf -- "$t"
    else
      cargo clean --quiet --manifest-path "$project/Cargo.toml" || rm -rf -- "$t"
    fi
  fi
done

total=$(numfmt --to=iec --from-unit=1024 "$total_kb")
if ((APPLY)); then
  echo "cleaned $count target dirs, freed ~$total"
else
  echo "$count target dirs, ~$total reclaimable (dry run, pass --yes to clean)"
fi
