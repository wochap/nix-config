# remote-desktop-connect
#
# Streams a remote desktop through Moonlight, fullscreen on this machine. Works
# from a bare TTY (starts cage) or from inside a Wayland session. Sunshine's
# prep commands fit the host's desktop to the requested mode for the session
# (remote-display) and put its own layout back when the app quits.
# REMOTE_HOSTS_FILE (JSON, name -> { address, app, maxFps, ... }) comes from
# the Nix module.
#
#   remote-desktop <host> [mirror|headless] [--resolution WxH] [--fps N] [--backend cage|eglfs]
#   remote-desktop --list

usage() {
  sed -n '/^#   remote-desktop/s/^#   //p' "$0" >&2
  echo "hosts: $(jq -r 'keys | join(" ")' "$REMOTE_HOSTS_FILE")" >&2
  exit 2
}

name="${1:-}"
if [[ "$name" == "--list" ]]; then
  jq -r 'keys[]' "$REMOTE_HOSTS_FILE"
  exit 0
fi
if [[ -z "$name" ]] || ! jq -e --arg name "$name" 'has($name)' "$REMOTE_HOSTS_FILE" >/dev/null; then
  usage
fi
shift

host_value() {
  jq -r --arg name "$name" ".[\$name].$1" "$REMOTE_HOSTS_FILE"
}
host=$(host_value address)
app=$(host_value app)
max_fps=$(host_value maxFps)
bitrate=$(host_value bitrate)
mapfile -t extra_args < <(jq -r --arg name "$name" '.[$name].extraArgs[]' "$REMOTE_HOSTS_FILE")

mode="mirror"
resolution=""
fps=""
backend="cage"

while [[ $# -gt 0 ]]; do
  case "$1" in
  mirror | headless) mode="$1" ;;
  --resolution)
    resolution="$2"
    shift
    ;;
  --fps)
    fps="$2"
    shift
    ;;
  --backend)
    backend="$2"
    shift
    ;;
  *) usage ;;
  esac
  shift
done

# the host maps each mode to its own Sunshine app
if [[ "$mode" == "headless" ]]; then
  app="$app Headless"
fi

detect_mode() {
  local randr_json
  randr_json=$(mktemp)

  if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
    wlr-randr --json >"$randr_json" 2>/dev/null || true
  elif [[ "$backend" == "cage" ]]; then
    # brief cage run, only to ask the compositor for the native mode
    # shellcheck disable=SC2016 # expanded by the inner sh
    cage -s -- sh -c 'wlr-randr --json > "$1"' _ "$randr_json" >/dev/null 2>&1 || true
  fi

  # inside a session keep the current mode; cage starts in the monitor's
  # preferred mode (often 60 Hz), so pick the largest, fastest one instead
  local filter='.modes[] | select(.current)'
  if [[ -z "${WAYLAND_DISPLAY:-}" ]]; then
    filter='.modes | max_by([.width * .height, .refresh])'
  fi
  local current
  current=$(jq -r "first(.[] | select(.enabled) | {name, mode: ($filter)})
    | \"\\(.mode.width)x\\(.mode.height) \\(.mode.refresh | round) \\(.name) \\(.mode.refresh)\"" \
    "$randr_json" 2>/dev/null || true)
  rm -f "$randr_json"

  if [[ -z "$current" ]]; then
    # no compositor answer, first connected connector's preferred mode
    local connector
    for connector in /sys/class/drm/card*-*; do
      if [[ "$(cat "$connector/status" 2>/dev/null)" == "connected" ]]; then
        current="$(head -n 1 "$connector/modes") 60 - -"
        break
      fi
    done
  fi

  [[ -n "$current" ]] || {
    echo "remote-desktop: cannot detect monitor mode, pass --resolution and --fps" >&2
    exit 1
  }
  echo "$current"
}

# mode cage switches the monitor to, "-" when unknown
cage_output="-"
cage_mode="-"
if [[ -z "$resolution" || -z "$fps" ]]; then
  read -r detected_resolution detected_fps cage_output cage_refresh <<<"$(detect_mode)"
  if [[ "$cage_output" != "-" ]]; then
    cage_mode="${detected_resolution}@${cage_refresh}"
  fi
  resolution="${resolution:-$detected_resolution}"
  fps="${fps:-$detected_fps}"
fi
if ((fps > max_fps)); then
  fps="$max_fps"
fi
width="${resolution%x*}"
height="${resolution#*x}"

echo "remote-desktop: $host $mode ${width}x${height}@${fps}"

# `moonlight quit` hangs on an unpaired host
if ! QT_QPA_PLATFORM=offscreen timeout 20 moonlight list "$host" >/dev/null 2>&1; then
  echo "remote-desktop: $host is not paired or not reachable, run 'moonlight pair $host' from a graphical session" >&2
  exit 1
fi

moonlight_quit() {
  QT_QPA_PLATFORM=offscreen timeout 10 moonlight quit "$host" >/dev/null 2>&1
}

# end a session another client left running (Moonlight on Android keeps the
# app on disconnect): resuming it keeps its display size, and launching the
# other mode's app fails while it runs. Quitting restores the host and the
# launch below applies this monitor's mode.
moonlight_quit || true

cleanup() {
  # finish even when Ctrl+C is pressed again
  trap '' INT TERM HUP
  trap - EXIT
  echo "remote-desktop: quitting the session on $host"
  # Sunshine's undo restores the host's layout; retry so a short network
  # drop does not leave it changed
  local attempt
  for attempt in 1 2 3 4 5 6 7 8 9 10; do
    if moonlight_quit; then
      return
    fi
    echo "remote-desktop: quit failed (attempt $attempt), retrying" >&2
    sleep 3
  done
  echo "remote-desktop: run 'remote-display restore' on $host" >&2
}
trap cleanup EXIT INT TERM HUP

# borderless: SDL's exclusive fullscreen fakes a mode change on Wayland,
# which scales the picture and leaves black bars.
# Super combos go to the host; Ctrl+Alt+Shift+Z still releases the grab.
# AV1 without 4:4:4: sharper than the H.264 fallback Moonlight picks when the
# host encoder lacks 4:4:4.
# No --quit-after: leaving the VT would end the Sunshine app, whose undo
# restores the host; cleanup quits the app on a real exit instead.
stream=(moonlight stream "$host" "$app"
  --resolution "${width}x${height}" --fps "$fps"
  --display-mode borderless --capture-system-keys always
  --no-yuv444 --video-codec AV1)
if [[ "$bitrate" != "null" ]]; then
  stream+=(--bitrate "$bitrate")
fi
stream+=("${extra_args[@]}")

night_light="$REMOTE_NIGHT_LIGHT"
if [[ -z "$night_light" ]]; then
  night_light=$(hyprctl -i 0 hyprsunset temperature 2>/dev/null | grep -xE '[0-9]+' || true)
fi

# from a TTY, local-keys keeps volume keys here (Moonlight drops them) and,
# with --grab, Ctrl+Alt+Fn. It runs until the stream ends.
local_keys_fd=""
local_keys_pid=""
start_local_keys() {
  local ready=""
  [[ -n "$own_vt" ]] || return 0
  exec {local_keys_fd}< <(exec remote-desktop-local-keys "${own_vt#tty}" "$@")
  local_keys_pid=$!
  read -r -t 5 -u "$local_keys_fd" ready || true
  [[ "$ready" == ready ]] || echo "remote-desktop: local keys not available (volume, Ctrl+Alt+Fn)" >&2
}
stop_local_keys() {
  [[ -n "$local_keys_pid" ]] || return 0
  kill "$local_keys_pid" 2>/dev/null || true
  exec {local_keys_fd}<&-
  local_keys_pid=""
}

run_stream() {
  local status=0
  if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
    # the local compositor's volume binds need to bypass Moonlight's
    # shortcut inhibitor (Hyprland: dont_inhibit)
    "${stream[@]}" || status=$?
  elif [[ "$backend" == "cage" ]]; then
    # cage switches VT itself, local-keys only reads the volume keys
    start_local_keys
    # -d: no client-side decorations; SDL's libdecor fallback frame otherwise
    # shrinks the picture and leaves bars on the left, right and bottom.
    # cage leaves the CRTC's color matrix alone, so a night light set by the
    # local Hyprland session (hyprsunset) stays on.
    # shellcheck disable=SC2016 # expanded by the inner sh
    cage -d -s -- sh -c '
      [ "$1" = - ] || wlr-randr --output "$1" --mode "$2" >/dev/null 2>&1 || true
      shift 2
      exec "$@"
    ' _ "$cage_output" "$cage_mode" "${stream[@]}" || status=$?
    stop_local_keys
  elif [[ "$backend" == "eglfs" ]]; then
    # no compositor keeps hyprsunset's color matrix here, so set it on the
    # CRTC while nobody holds DRM master, right before Moonlight takes it
    if [[ -n "$night_light" ]]; then
      drm-night-light "$night_light" || echo "remote-desktop: night light not applied" >&2
    fi
    # Moonlight forwards Ctrl+Alt+Fn to the host and SDL mutes the console
    # keyboard; local-keys grabs the keyboards to keep those combos here
    start_local_keys --grab
    QT_QPA_PLATFORM=eglfs QT_QPA_EGLFS_INTEGRATION=eglfs_kms "${stream[@]}" || status=$?
    stop_local_keys
  else
    usage
  fi
  return "$status"
}

# from a TTY, switching VT makes cage or Moonlight exit. Keep the host
# session, wait until this VT is active again and reconnect. Any exit while
# the VT is active is a real quit.
own_vt=""
if [[ -z "${WAYLAND_DISPLAY:-}" ]]; then
  own_vt=$(tty 2>/dev/null || true)
  own_vt="${own_vt#/dev/}"
  [[ "$own_vt" == tty[0-9]* ]] || own_vt=""
fi

vt_active() {
  [[ "$(cat /sys/class/tty/tty0/active 2>/dev/null)" == "$own_vt" ]]
}

while true; do
  run_stream || true
  if [[ -z "$own_vt" ]] || vt_active; then
    break
  fi
  echo "remote-desktop: left $own_vt, reconnecting when it is active again (Ctrl+C here to stop)"
  until vt_active; do
    sleep 1
  done
  # let logind hand the seat back first
  sleep 1
done
