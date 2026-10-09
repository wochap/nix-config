# shellcheck shell=bash disable=SC2154 # state_file and output come from remote-display.sh
# Hyprland provider for remote-display, sourced by remote-display.sh.
#
# Streams always come from a headless output ($output) sized to the client.
# In mirror mode every physical output mirrors it, so the local screen shows
# the stream and local input keeps working. Hyprland cannot keep workspaces
# on a mirror, so they move to $output and come back on restore. The local
# cursor then lives in $output's coordinate space.
#
# kanshi would treat the new output as a profile change and
# override the mode, so it stays stopped until restore.

hypr_env() {
  # ssh sessions do not inherit the compositor's environment
  if [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    local session_env
    session_env=$(systemctl --user show-environment 2>/dev/null || true)
    HYPRLAND_INSTANCE_SIGNATURE=$(sed -n 's/^HYPRLAND_INSTANCE_SIGNATURE=//p' <<<"$session_env")
    WAYLAND_DISPLAY=$(sed -n 's/^WAYLAND_DISPLAY=//p' <<<"$session_env")
    if [[ -z "$HYPRLAND_INSTANCE_SIGNATURE" ]]; then
      # newest instance
      HYPRLAND_INSTANCE_SIGNATURE=$(find "$XDG_RUNTIME_DIR/hypr" -mindepth 1 -maxdepth 1 -type d -printf '%T@ %f\n' |
        sort -nr | head -n 1 | cut -d ' ' -f 2)
    fi
    export HYPRLAND_INSTANCE_SIGNATURE WAYLAND_DISPLAY
  fi
}

hypr_monitor() {
  # $1: Lua table body for hl.monitor
  hyprctl eval "hl.monitor({ $1 })" >/dev/null
}

kanshi_present() {
  systemctl --user cat kanshi.service >/dev/null 2>&1
}

provider_apply() {
  local mode="$1" width="$2" height="$3" fps="$4" scale="$5"
  hypr_env

  if [[ ! -f "$state_file" ]]; then
    # snapshot before stopping kanshi, so it holds the real hardware layout
    jq -n \
      --argjson monitors "$(hyprctl monitors all -j)" \
      --argjson workspaces "$(hyprctl workspaces -j)" \
      --argjson active "$(hyprctl activeworkspace -j)" \
      --arg mode "$mode" \
      '{ $monitors, $workspaces, $active, $mode }' >"$state_file.tmp"
    mv "$state_file.tmp" "$state_file"

    if kanshi_present; then
      systemctl --user stop kanshi.service
    fi

    # leftover from other scripts or a crashed session
    hyprctl output remove "$output" >/dev/null || true
    hyprctl output create headless "$output" >/dev/null
    sleep 0.2
  fi

  hypr_monitor "output = \"$output\", mode = \"${width}x${height}@${fps}\", position = \"auto\", scale = $scale"

  if [[ "$mode" == "mirror" ]]; then
    # keep each output's current mode, "preferred" can mean a different
    # refresh rate and an extra modeset
    local name physical_mode physical_scale
    while read -r name physical_mode physical_scale; do
      hypr_monitor "output = \"$name\", mode = \"$physical_mode\", position = \"auto\", scale = $physical_scale, mirror = \"$output\""
    done < <(jq -r --arg output "$output" \
      '.monitors[] | select(.disabled | not) | select(.name != $output) | select(.name | startswith("HEADLESS-") | not) | "\(.name) \(.width)x\(.height)@\(.refreshRate) \(.scale)"' \
      "$state_file")
  fi
}

provider_restore() {
  hypr_env

  hyprctl output remove "$output" >/dev/null || true
  # drop the runtime monitor rules (mirror, custom modes)
  hyprctl reload >/dev/null || true
  sleep 0.5

  if kanshi_present; then
    # kanshi picks the profile for the current hardware again
    systemctl --user start kanshi.service
    sleep 1
  else
    local rule
    while read -r rule; do
      hypr_monitor "$rule"
    done < <(jq -r '.monitors[] | select(.disabled | not) | select(.name | startswith("HEADLESS-") | not)
      | "output = \"\(.name)\", mode = \"\(.width)x\(.height)@\(.refreshRate)\", position = \"\(.x)x\(.y)\", scale = \(.scale)"' \
      "$state_file")
    sleep 0.5
  fi

  # workspaces left behind on the removed output end up without a monitor
  local current_monitors workspace monitor
  current_monitors=$(hyprctl monitors -j | jq -r '.[].name')
  while IFS=$'\t' read -r workspace monitor; do
    if grep -qxF "$monitor" <<<"$current_monitors"; then
      hyprctl eval "hl.dispatch(hl.dsp.workspace.move({ workspace = \"$workspace\", monitor = \"$monitor\" }))" >/dev/null || true
    fi
  done < <(jq -r '.workspaces[] | "\(.name)\t\(.monitor)"' "$state_file")

  # workspaces opened on $output during the stream are not in the snapshot and
  # stay orphaned (monitor "?"), unreachable until moved to a real output
  local fallback
  fallback=$(jq -r '.active.monitor' "$state_file")
  grep -qxF "$fallback" <<<"$current_monitors" || fallback=$(head -n 1 <<<"$current_monitors")
  while read -r workspace; do
    hyprctl eval "hl.dispatch(hl.dsp.workspace.move({ workspace = \"$workspace\", monitor = \"$fallback\" }))" >/dev/null || true
  done < <(hyprctl workspaces -j | jq -r --arg monitors "$current_monitors" \
    '($monitors | split("\n")) as $names | .[] | select(.id > 0) | select(.monitor as $m | $names | index($m) | not) | .name')

  # the cursor was on the removed output, Hyprland stays without a focused
  # monitor ("unsafe state") until it lands on a real one
  local cursor
  cursor=$(hyprctl monitors -j | jq -r --arg name "$(jq -r '.active.monitor' "$state_file")" \
    '(map(select(.name == $name)) + .)[0] | "x = \((.x + .width / .scale / 2) | floor), y = \((.y + .height / .scale / 2) | floor)"')
  hyprctl eval "hl.dispatch(hl.dsp.cursor.move({ $cursor }))" >/dev/null || true

  # outputs coming back can still switch to a fresh workspace, so retry
  local attempt
  workspace=$(jq -r '.active.name' "$state_file")
  for attempt in 1 2 3 4 5; do
    hyprctl eval "hl.dispatch(hl.dsp.focus({ workspace = \"$workspace\" }))" >/dev/null || true
    sleep 0.3
    if [[ "$(hyprctl activeworkspace -j 2>/dev/null | jq -r '.name' 2>/dev/null)" == "$workspace" ]]; then
      break
    fi
    echo "remote-display: focus attempt $attempt failed" >&2
  done
}

provider_status() {
  hypr_env

  if [[ -f "$state_file" ]]; then
    echo "applied ($(jq -r '.mode' "$state_file"))"
  else
    echo "not applied"
  fi
  hyprctl monitors all -j | jq -r '.[] | "\(.name) \(.width)x\(.height)@\(.refreshRate) scale \(.scale) mirror \(.mirrorOf) disabled \(.disabled)"'
}
