# Run course-notes on every transcript under a directory, recursively.
# A transcript is a text file with [MM:SS.xx] timestamps; its notes are
# written next to it as <stem>_note.md.

usage() {
  echo "Usage: course-notes-dir [--force] <dir> [course-notes options...]" >&2
  echo "  --force  regenerate notes that already exist" >&2
}

force=0
if [[ "${1:-}" == "--force" ]]; then
  force=1
  shift
fi
if [[ $# -lt 1 || "$1" == "-h" || "$1" == "--help" ]]; then
  usage
  exit 1
fi

dir="$1"
shift
if [[ ! -d "$dir" ]]; then
  echo "Error: not a directory: $dir" >&2
  exit 1
fi

done_count=0
skipped=0
failed=()

# -I skips binary files; generated notes are never transcripts.
while IFS= read -r -d '' file; do
  note="${file%.*}_note.md"
  if [[ $force -eq 0 && -e "$note" ]]; then
    echo "Exists, skipping: $note" >&2
    skipped=$((skipped + 1))
    continue
  fi

  echo "==> $file" >&2
  if course-notes --require-timestamps "$@" "$file"; then
    done_count=$((done_count + 1))
  else
    failed+=("$file")
  fi
done < <(
  find "$dir" -type f ! -name '*_note.md' -print0 |
    xargs -0 -r grep -lIZE '\[[0-9]{2}:[0-9]{2}\.[0-9]{2}\]' |
    sort -z
)

echo "Done: $done_count generated, $skipped skipped, ${#failed[@]} failed" >&2
for file in "${failed[@]}"; do
  echo "  failed: $file" >&2
done
[[ ${#failed[@]} -eq 0 ]]
