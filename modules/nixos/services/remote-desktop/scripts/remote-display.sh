# remote-display
#
# Fits this host's desktop to a remote client's monitor while it streams
# through Sunshine, then puts the original layout back. Display work happens
# in a provider (scripts/providers/<name>.sh) that defines provider_apply,
# provider_restore and provider_status, optionally provider_watch. Sunshine
# runs apply and restore as the app's prep commands. reapply puts the
# session's display back after something reset it (a config reload, e.g. from
# nixos-rebuild switch), optionally with another size or scale. When the
# provider has provider_watch, apply starts it as a user unit that runs
# reapply on its own, and restore stops it. REMOTE_DISPLAY_PROVIDERS, REMOTE_DISPLAY_OUTPUT and
# REMOTE_DISPLAY_SCALES (JSON, "WxH" -> scale) come from the Nix module.
#
#   remote-display apply --mode mirror|headless --width W --height H --fps F [--scale S]
#   remote-display reapply [--width W --height H] [--fps F] [--scale S]
#   remote-display restore
#   remote-display status

usage() {
  sed -n '/^#   remote-display/s/^#   //p' "$0" >&2
  exit 2
}

state_dir="${XDG_RUNTIME_DIR:?XDG_RUNTIME_DIR is not set}/remote-display"
state_file="$state_dir/state.json"
# the last apply's arguments, for reapply
request_file="$state_dir/request.json"
watch_unit="remote-display-watch"
self=$(realpath "$0")
# shellcheck disable=SC2034 # read by the provider
output="$REMOTE_DISPLAY_OUTPUT"
mkdir -p "$state_dir"

provider=""
mode="mirror"
width=""
height=""
fps="60"
scale=""

command="${1:-}"
[[ -n "$command" ]] || usage
shift

# Sunshine's undo, its ExecStopPost, the watcher and a manual restore can
# overlap, so every command runs under one lock. The watcher only waits; the
# reapply it runs takes the lock.
if [[ "$command" != "watch" ]]; then
  exec 9>"$state_dir/lock"
  flock 9
fi

if [[ "$command" == "reapply" ]]; then
  if [[ ! -f "$state_file" || ! -f "$request_file" ]]; then
    echo "remote-display: nothing applied" >&2
    exit 1
  fi
  IFS=$'\t' read -r width height fps scale < <(jq -r '[.width, .height, .fps, .scale] | @tsv' "$request_file")
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
  --provider) provider="$2" ;;
  --mode) mode="$2" ;;
  --width) width="$2" ;;
  --height) height="$2" ;;
  --fps) fps="$2" ;;
  --scale) scale="$2" ;;
  *) usage ;;
  esac
  shift 2
done

if [[ -z "$provider" ]]; then
  if [[ -d "$XDG_RUNTIME_DIR/hypr" ]]; then
    provider="hyprland"
  else
    echo "remote-display: no supported desktop found, pass --provider" >&2
    exit 1
  fi
fi

provider_file="$REMOTE_DISPLAY_PROVIDERS/$provider.sh"
if [[ ! -f "$provider_file" ]]; then
  echo "remote-display: unknown provider '$provider'" >&2
  exit 1
fi
# shellcheck source=/dev/null
source "$provider_file"

start_watch() {
  declare -F provider_watch >/dev/null || return 0
  systemctl --user is-active --quiet "$watch_unit" && return 0
  systemctl --user reset-failed "$watch_unit" 2>/dev/null || true
  systemd-run --user --quiet --collect --unit "$watch_unit" \
    --description "Reapply remote-display after config reloads" \
    "$self" watch --provider "$provider" ||
    echo "remote-display: watcher not started, run 'remote-display reapply' after a config reload" >&2
}

case "$command" in
apply | reapply)
  # reapply keeps the session's mode, mirror outputs are set up for it
  if [[ "$command" == "reapply" ]]; then
    mode=$(jq -r '.mode' "$request_file")
  fi
  [[ "$mode" == "mirror" || "$mode" == "headless" ]] || usage
  [[ -n "$width" && -n "$height" ]] || usage
  if [[ -z "$scale" ]]; then
    scale=$(jq -r --arg resolution "${width}x${height}" '.[$resolution] // 1' <<<"$REMOTE_DISPLAY_SCALES")
  fi
  echo "remote-display: $command $mode ${width}x${height}@${fps} scale $scale" >&2
  provider_apply "$mode" "$width" "$height" "$fps" "$scale"
  jq -n --arg mode "$mode" --arg width "$width" --arg height "$height" --arg fps "$fps" --arg scale "$scale" \
    '{ $mode, $width, $height, $fps, $scale }' >"$request_file"
  start_watch
  ;;
restore)
  # a stopping Sunshine or Ctrl+C must not stop it halfway
  trap '' HUP INT TERM
  # before the provider's own reload, which the watcher would undo
  systemctl --user stop "$watch_unit" 2>/dev/null || true
  if [[ ! -f "$state_file" ]]; then
    # nothing applied, or the other restore already ran
    exit 0
  fi
  provider_restore
  rm -f "$state_file" "$request_file"
  ;;
watch)
  declare -F provider_watch >/dev/null || exit 0
  provider_watch "$self"
  ;;
status)
  provider_status
  ;;
*)
  usage
  ;;
esac
