#!/usr/bin/env bash
set -euo pipefail

validate_args=()
if [[ ${1:-} == --validate ]]; then
  validate_args=(--validate)
  shift
fi
dir="${1:-.}"
if (($# > 1)); then
  echo "usage: asr-videos.sh [--validate] [DIRECTORY]" >&2
  exit 2
fi

mapfile -d '' files < <(find "$dir" -type f -name '*.mp4' -print0 | sort -zV)

for file in "${files[@]}"; do
  base="${file%.mp4}"
  if [[ -f "$base.txt" && -f "$base.json" ]]; then
    echo "Skipping: $file" >&2
    continue
  fi
  echo "Processing: $file" >&2
  qwen3-asr-video --language es "${validate_args[@]}" "$file"
done
