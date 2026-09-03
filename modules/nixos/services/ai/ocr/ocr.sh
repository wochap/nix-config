#!/usr/bin/env bash

# source theme colors
source "$HOME/.config/scripts/theme-colors.sh"

mode="${1:-rapid}"
case "$mode" in
  rapid | glm) ;;
  *)
    echo "usage: ocr [rapid|glm]" >&2
    exit 2
    ;;
esac

notify_error() {
  notify-send \
    --app-name="ocr" \
    --urgency=critical \
    --hint=int:transient:1 \
    "OCR Failed" \
    "$1"
}

wayfreeze_pid=""
temp_dir=""

stop_wayfreeze() {
  if [[ -n "$wayfreeze_pid" ]] && kill -0 "$wayfreeze_pid" 2>/dev/null; then
    kill "$wayfreeze_pid" 2>/dev/null || true
    wait "$wayfreeze_pid" 2>/dev/null || true
  fi
  wayfreeze_pid=""
}

cleanup() {
  stop_wayfreeze
  if [[ -n "$temp_dir" ]]; then
    rm -f -- \
      "$temp_dir/capture.png" \
      "$temp_dir/error.log" \
      "$temp_dir/output.txt" \
      "$temp_dir/request.json" \
      "$temp_dir/response.json"
    rmdir -- "$temp_dir" 2>/dev/null || true
  fi
}

trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' HUP TERM

lock_file="${XDG_RUNTIME_DIR:-/tmp}/ocr-${UID}.lock"
exec 9>"$lock_file"
if ! flock --nonblock 9; then
  notify_error "Another OCR selection is already running"
  exit 1
fi

temp_dir="$(mktemp --directory --tmpdir="${XDG_RUNTIME_DIR:-/tmp}" ocr.XXXXXX)"
image_file="$temp_dir/capture.png"
error_file="$temp_dir/error.log"
output_file="$temp_dir/output.txt"

wayfreeze --hide-cursor &
wayfreeze_pid=$!
sleep 0.1
if ! kill -0 "$wayfreeze_pid" 2>/dev/null; then
  wait "$wayfreeze_pid" 2>/dev/null || true
  wayfreeze_pid=""
  notify_error "Could not freeze the screen"
  exit 1
fi

if ! area="$(
  slurp \
    -d \
    -b "${background}bf" \
    -c "$primary" \
    -F "Iosevka NF" \
    -w 1
)"; then
  exit 0
fi
if [[ -z "$area" ]]; then
  exit 0
fi

if ! grim -g "$area" "$image_file" 2>"$error_file"; then
  notify_error "Could not capture the selected region"
  exit 1
fi
stop_wayfreeze

case "$mode" in
  rapid)
    if ! "$OCR_RAPID_PYTHON" \
      "$OCR_RAPID_ENTRYPOINT" \
      "$image_file" \
      >"$output_file" \
      2>"$error_file"; then
      notify_error "RapidOCR inference failed"
      exit 1
    fi
    success_title="RapidOCR Completed"
    ;;
  glm)
    request_file="$temp_dir/request.json"
    response_file="$temp_dir/response.json"
    if ! base64 --wrap=0 "$image_file" | jq --raw-input --slurp '{
      model: "glm-ocr:bf16",
      prompt: "Text Recognition:",
      images: [.],
      stream: false,
      keep_alive: "15m"
    }' >"$request_file"; then
      notify_error "Could not prepare the GLM-OCR request"
      exit 1
    fi
    if ! curl \
      --silent \
      --show-error \
      --fail-with-body \
      --connect-timeout 2 \
      --header "Content-Type: application/json" \
      --data-binary "@$request_file" \
      "http://127.0.0.1:11434/api/generate" \
      >"$response_file" \
      2>"$error_file"; then
      notify_error "GLM-OCR is unavailable or inference failed"
      exit 1
    fi
    if ! jq \
      --exit-status \
      --join-output \
      '.response | select(type == "string")' \
      "$response_file" \
      >"$output_file" \
      2>"$error_file"; then
      notify_error "GLM-OCR returned an invalid response"
      exit 1
    fi
    success_title="GLM-OCR Completed"
    ;;
esac

if ! jq --exit-status --raw-input --slurp 'test("\\S")' "$output_file" >/dev/null; then
  notify_error "No text was recognized"
  exit 1
fi

if ! wl-copy --trim-newline <"$output_file"; then
  notify_error "Could not copy OCR output to the clipboard"
  exit 1
fi

notify-send \
  --app-name="ocr" \
  --hint=int:transient:1 \
  "$success_title" \
  "Text extracted and copied"
