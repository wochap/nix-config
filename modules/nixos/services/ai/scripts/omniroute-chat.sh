#!/usr/bin/env bash
set -euo pipefail

base_url="${OMNIROUTE_BASE_URL:-https://omniroute.wochap.local/v1}"
model="${OMNIROUTE_MODEL:-desktop-free}"
api_key_file="${OMNIROUTE_API_KEY_FILE:-/run/secrets/local-omniroute-secret-key}"

usage() {
  echo "usage: omniroute-chat [--model MODEL] < OpenAI-chat-request.json" >&2
}

while (($#)); do
  case "$1" in
  --model)
    (($# >= 2)) || { usage; exit 2; }
    model=$2
    shift 2
    ;;
  --help | -h)
    usage
    exit 0
    ;;
  *)
    usage
    exit 2
    ;;
  esac
done

if [[ -n ${OMNIROUTE_API_KEY:-} ]]; then
  api_key=$OMNIROUTE_API_KEY
elif [[ -r $api_key_file ]]; then
  api_key=$(<"$api_key_file")
else
  echo "omniroute-chat: set OMNIROUTE_API_KEY or provide readable key file: $api_key_file" >&2
  exit 1
fi

work_dir=$(mktemp -d "${TMPDIR:-/tmp}/omniroute-chat.XXXXXX")
trap 'rm -rf "$work_dir"' EXIT

if ! jq -e --arg model "$model" '
  select(type == "object" and (.messages | type == "array")) |
  .model = $model | .stream = false
' >"$work_dir/request.json"; then
  echo "omniroute-chat: stdin must be an OpenAI chat request with a messages array" >&2
  exit 2
fi

if ! http_code=$(curl --silent --show-error --connect-timeout 5 --max-time 120 \
  --output "$work_dir/response.json" --write-out '%{http_code}' \
  --header 'Content-Type: application/json' \
  --header "Authorization: Bearer $api_key" \
  --data-binary @"$work_dir/request.json" \
  "${base_url%/}/chat/completions"); then
  echo "omniroute-chat: could not reach OmniRoute at $base_url" >&2
  exit 1
fi

if [[ $http_code != 2* ]]; then
  error=$(jq -r '.error.message // .error // .message // empty' "$work_dir/response.json" 2>/dev/null || true)
  [[ -n $error ]] || error=$(head -c 500 "$work_dir/response.json")
  echo "omniroute-chat: OmniRoute returned HTTP $http_code: $error" >&2
  exit 1
fi

if ! jq -er '.choices[0].message.content | select(type == "string" and length > 0)' \
  "$work_dir/response.json"; then
  echo "omniroute-chat: OmniRoute returned no usable message content" >&2
  exit 1
fi
