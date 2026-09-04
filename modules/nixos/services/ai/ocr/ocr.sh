#!/usr/bin/env bash

# source theme colors
# shellcheck source=/dev/null
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

wayfreeze_pid=""
temp_dir=""
screen_shader=""
screen_shader_disabled=false

disable_screen_shader() {
  if $screen_shader_disabled; then
    return
  fi

  screen_shader=$(hyprctl getoption decoration.screen_shader | sed -n '1s/^str:[[:space:]]*//p')
  if hyprctl keyword decoration:screen_shader "" >/dev/null; then
    screen_shader_disabled=true
    # Let Hyprland render an unfiltered frame before a screencopy client runs.
    sleep 0.05
  fi
}

restore_screen_shader() {
  if ! $screen_shader_disabled; then
    return
  fi

  if hyprctl keyword decoration:screen_shader "$screen_shader" >/dev/null; then
    screen_shader_disabled=false
    sleep 0.05
  fi
}

capture_grim() {
  local status

  disable_screen_shader
  grim "$@"
  status=$?
  restore_screen_shader
  return "$status"
}

stop_wayfreeze() {
  if [[ -n "$wayfreeze_pid" ]] && kill -0 "$wayfreeze_pid" 2>/dev/null; then
    kill "$wayfreeze_pid" 2>/dev/null || true
    wait "$wayfreeze_pid" 2>/dev/null || true
  fi
  wayfreeze_pid=""
}

cleanup() {
  restore_screen_shader
  stop_wayfreeze
  if [[ -n "$temp_dir" ]]; then
    rm -f -- \
      "$temp_dir/capture.png" \
      "$temp_dir/error.log" \
      "$temp_dir/output.txt" \
      "$temp_dir/request.json" \
      "$temp_dir/response.json" \
      "$temp_dir/sanitized.txt"
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

# wayfreeze stores a screencopy as its backing surface. Freeze the screen
# without the shader, then restore the shader while the area is selected.
disable_screen_shader
wayfreeze --hide-cursor &
wayfreeze_pid=$!
sleep 0.1
if ! kill -0 "$wayfreeze_pid" 2>/dev/null; then
  wait "$wayfreeze_pid" 2>/dev/null || true
  wayfreeze_pid=""
  restore_screen_shader
  notify_error "Could not freeze the screen"
  exit 1
fi
restore_screen_shader

# background and primary are provided by theme-colors.sh.
# shellcheck disable=SC2154
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

if ! capture_grim -g "$area" "$image_file" 2>"$error_file"; then
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
      keep_alive: "15m",
      options: {
        temperature: 0,
        num_predict: 4096
      }
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
  sanitized_file="$temp_dir/sanitized.txt"
  if ! sanitize_glm_output "$output_file" "$sanitized_file" ||
    ! mv -- "$sanitized_file" "$output_file"; then
    notify_error "Could not sanitize the GLM-OCR response"
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
