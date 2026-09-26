#!/usr/bin/env bash

# source theme colors
# shellcheck source=/dev/null
source "$HOME/.config/scripts/theme-colors.sh"

# OCR_ADAPTER_COMMANDS, OCR_ADAPTER_LABELS, and OCR_DEFAULT_ADAPTER come from
# the prelude the NixOS module puts in front of this script. An adapter
# command takes the captured image, prints the text on stdout, and explains a
# failure on the last stderr line.
mode="${1:-$OCR_DEFAULT_ADAPTER}"
mode_known=false
for adapter in "${!OCR_ADAPTER_COMMANDS[@]}"; do
  if [[ $adapter == "$mode" ]]; then
    mode_known=true
  fi
done
if ! $mode_known; then
  echo "usage: ocr [$(printf '%s\n' "${!OCR_ADAPTER_COMMANDS[@]}" | sort | paste -sd '|')]" >&2
  exit 2
fi

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
screen_shader=""
screen_shader_disabled=false

disable_screen_shader() {
  if $screen_shader_disabled; then
    return
  fi

  screen_shader=$(hyprctl getoption decoration.screen_shader | sed -n '1s/^str:[[:space:]]*//p')
  if hyprctl eval 'hl.config({ decoration = { screen_shader = "" } })' >/dev/null; then
    screen_shader_disabled=true
    sleep 0.05
  fi
}

restore_screen_shader() {
  if ! $screen_shader_disabled; then
    return
  fi

  if hyprctl eval "hl.config({ decoration = { screen_shader = \"$screen_shader\" } })" >/dev/null; then
    screen_shader_disabled=false
    sleep 0.05
  fi
}

capture_grim() {
  local status

  grim "$@"
  status=$?
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
  stop_wayfreeze
  restore_screen_shader
  if [[ -n "$temp_dir" ]]; then
    rm -f -- \
      "$temp_dir/capture.png" \
      "$temp_dir/error.log" \
      "$temp_dir/output.txt"
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
sleep 0.05
if ! kill -0 "$wayfreeze_pid" 2>/dev/null; then
  wait "$wayfreeze_pid" 2>/dev/null || true
  wayfreeze_pid=""
  restore_screen_shader
  notify_error "Could not freeze the screen"
  exit 1
fi

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
  stop_wayfreeze
  restore_screen_shader
  notify_error "Could not capture the selected region"
  exit 1
fi
stop_wayfreeze
restore_screen_shader

label="${OCR_ADAPTER_LABELS[$mode]}"
if ! "${OCR_ADAPTER_COMMANDS[$mode]}" \
  "$image_file" \
  >"$output_file" \
  2>"$error_file"; then
  reason="$(tail -n 1 -- "$error_file")"
  notify_error "$label failed${reason:+: $reason}"
  exit 1
fi

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
  "$label Completed" \
  "Text extracted and copied"
