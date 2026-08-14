#!/usr/bin/env bash

set -euo pipefail

readonly endpoint="${SUPERTONIC_URL:-http://127.0.0.1:7788/v1/tts}"
readonly output_dir="${1:-./supertonic-eg-test}"
readonly voice="${SUPERTONIC_VOICE:-M1}"

command -v curl >/dev/null || {
  echo "curl is required" >&2
  exit 1
}
command -v jq >/dev/null || {
  echo "jq is required" >&2
  exit 1
}

mkdir -p "$output_dir"

readonly -a samples=(
  "### Key Takeaways"
  "e.g. with comma|Agents can learn incorrect associations, e.g., training cars as cows."
  "e.g. without comma|Agents can learn incorrect associations, e.g. training cars as cows."
  "e.g. in parentheses|Agents can learn incorrect associations (e.g., training cars as cows)."
  "e.g. near start|E.g., agents can learn incorrect associations, such as training cars as cows."
  "e.g. between sentences|Agents can learn incorrect associations. E.g., training cars as cows."
)

for index in "${!samples[@]}"; do
  label=${samples[index]%%|*}
  text=${samples[index]#*|}
  output=$(printf '%s/%02d.wav' "$output_dir" "$((index + 1))")

  printf '\n[%d/%d] %s\nText: %s\nFile: %s\n' \
    "$((index + 1))" "${#samples[@]}" "$label" "$text" "$output"

  jq -cn \
    --arg text "$text" \
    --arg voice "$voice" \
    '{text: $text, voice: $voice, steps: 5, speed: 1.5, max_chunk_length: 400, silence_duration: 0.15, response_format: "wav"}' |
    curl \
      --fail \
      --show-error \
      --silent \
      --header "content-type: application/json" \
      --data-binary @- \
      --output "$output" \
      "$endpoint"

  if command -v pw-play >/dev/null; then
    pw-play "$output"
  fi
done

printf '\nSaved %d test files in %s\n' "${#samples[@]}" "$output_dir"
if ! command -v pw-play >/dev/null; then
  echo "pw-play was not found; play the WAV files manually."
fi
