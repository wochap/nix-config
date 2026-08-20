#!/usr/bin/env bash
set -euo pipefail

dir="${1:-.}"

mapfile -d '' files < <(find "$dir" -type f -name '*.mp4' -print0 | sort -zV)

for file in "${files[@]}"; do
  base="${file%.mp4}"
  if [[ -f "$base.txt" && -f "$base.json" ]]; then
    echo "Skipping: $file" >&2
    continue
  fi
  echo "Processing: $file" >&2
  qwen3-asr-video --language es "$file"
done
