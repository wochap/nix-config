#!/usr/bin/env bash

# Screen adapter for ocr: recognizes IMAGE with GLM-OCR through the local
# Ollama server and prints the text on stdout. The last stderr line explains
# a failure.

if (($# != 1)); then
  echo "usage: ocr-glm IMAGE" >&2
  exit 2
fi
image_file=$1

fail() {
  echo "$1" >&2
  exit 1
}

sanitize_glm_output() {
  local input_file="$1"
  local sanitized_file="$2"

  # GLM-OCR can get stuck emitting empty Markdown code fences. If the response
  # ends with three or more standalone fences, keep the first one (normally the
  # legitimate closing fence) and discard the repeated suffix.
  awk '
    { lines[NR] = $0 }
    END {
      last = NR
      while (last > 0 && lines[last] ~ /^[[:space:]]*$/) {
        last--
      }

      run_end = last
      fence_count = 0
      while (last > 0) {
        if (lines[last] ~ /^[[:space:]]*```+[[:space:]]*$/) {
          fence_count++
          last--
        } else if (lines[last] ~ /^[[:space:]]*$/) {
          last--
        } else {
          break
        }
      }

      if (fence_count >= 3) {
        print_end = last + 1
        while (print_end <= run_end && lines[print_end] ~ /^[[:space:]]*$/) {
          print_end++
        }
      } else {
        print_end = run_end
      }

      for (line = 1; line <= print_end; line++) {
        print lines[line]
      }
    }
  ' "$input_file" >"$sanitized_file"
}

temp_dir="$(mktemp --directory --tmpdir="${XDG_RUNTIME_DIR:-/tmp}" ocr-glm.XXXXXX)"
trap 'rm -rf -- "$temp_dir"' EXIT

request_file="$temp_dir/request.json"
response_file="$temp_dir/response.json"
output_file="$temp_dir/output.txt"
sanitized_file="$temp_dir/sanitized.txt"

if ! base64 --wrap=0 "$image_file" | jq --raw-input --slurp --arg model "$OCR_GLM_MODEL" '{
    model: $model,
    prompt: "Text Recognition:",
    images: [.],
    stream: false,
    keep_alive: "15m",
    options: {
      temperature: 0,
      num_predict: 4096
    }
  }' >"$request_file"; then
  fail "Could not prepare the request"
fi
if ! curl \
  --silent \
  --show-error \
  --fail-with-body \
  --connect-timeout 2 \
  --header "Content-Type: application/json" \
  --data-binary "@$request_file" \
  "http://127.0.0.1:11434/api/generate" \
  >"$response_file"; then
  fail "Ollama is unavailable or inference failed"
fi
if ! jq \
  --exit-status \
  --join-output \
  '.response | select(type == "string")' \
  "$response_file" \
  >"$output_file"; then
  fail "Ollama returned an invalid response"
fi
if ! sanitize_glm_output "$output_file" "$sanitized_file"; then
  fail "Could not sanitize the response"
fi
cat -- "$sanitized_file"
