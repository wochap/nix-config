#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
usage: asr-videos [OPTIONS] [DIRECTORY]

Transcribe every MP4 file below DIRECTORY (default: current directory).
OPTIONS are passed to qwen3-asr-video:
  --language LANGUAGE
  --output, -o FILE
  --json-output FILE
  --num-speakers N
  --min-speakers N
  --max-speakers N
  --validate
  --help, -h
EOF
}

qwen_args=()
dir=.
directory_set=0
language_set=0

while (($#)); do
  case "$1" in
  --language | --output | -o | --json-output | --num-speakers | --min-speakers | --max-speakers)
    (($# >= 2)) || { usage; exit 2; }
    if [[ $1 == --language ]]; then
      language_set=1
    fi
    qwen_args+=("$1" "$2")
    shift 2
    ;;
  --validate)
    qwen_args+=("$1")
    shift
    ;;
  --help | -h)
    usage
    exit 0
    ;;
  --*)
    usage
    exit 2
    ;;
  *)
    ((directory_set == 0)) || { usage; exit 2; }
    dir=$1
    directory_set=1
    shift
    ;;
  esac
done

((language_set == 1)) || qwen_args=(--language es "${qwen_args[@]}")

mapfile -d '' files < <(find "$dir" -type f -name '*.mp4' -print0 | sort -zV)

for file in "${files[@]}"; do
  base="${file%.mp4}"
  if [[ -f "$base.txt" && -f "$base.json" ]]; then
    echo "Skipping: $file" >&2
    continue
  fi
  echo "Processing: $file" >&2
  qwen3-asr-video "${qwen_args[@]}" "$file"
done
