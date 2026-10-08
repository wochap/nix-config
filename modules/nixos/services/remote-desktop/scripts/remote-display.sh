# remote-display
#
# Fits this host's desktop to a remote client's monitor while it streams
# through Sunshine, then puts the original layout back. Display work happens
# in a provider (scripts/providers/<name>.sh) that defines provider_apply,
# provider_restore and provider_status. REMOTE_DISPLAY_PROVIDERS and
# REMOTE_DISPLAY_OUTPUT come from the Nix module.
#
#   remote-display apply --mode mirror|headless --width W --height H --fps F --scale S
#   remote-display restore
#   remote-display status

usage() {
  sed -n '/^#   remote-display/s/^#   //p' "$0" >&2
  exit 2
}

state_dir="${XDG_RUNTIME_DIR:?XDG_RUNTIME_DIR is not set}/remote-display"
state_file="$state_dir/state.json"
# shellcheck disable=SC2034 # read by the provider
output="$REMOTE_DISPLAY_OUTPUT"
mkdir -p "$state_dir"

# Sunshine's undo and the client's trap both call restore when a stream ends,
# so every command runs under one lock
exec 9>"$state_dir/lock"
flock 9

provider=""
mode="mirror"
width=""
height=""
fps="60"
scale="1"

command="${1:-}"
[[ -n "$command" ]] || usage
shift

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

case "$command" in
apply)
  [[ "$mode" == "mirror" || "$mode" == "headless" ]] || usage
  [[ -n "$width" && -n "$height" ]] || usage
  provider_apply "$mode" "$width" "$height" "$fps" "$scale"
  ;;
restore)
  # a dropped ssh connection or Ctrl+C on the client must not stop it halfway
  trap '' HUP INT TERM
  if [[ ! -f "$state_file" ]]; then
    # nothing applied, or the other restore already ran
    exit 0
  fi
  provider_restore
  rm -f "$state_file"
  ;;
status)
  provider_status
  ;;
*)
  usage
  ;;
esac
