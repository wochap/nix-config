# media-ctl: stop, start, restart, pause or resume groups of media containers.
#
# MEDIA_PROFILES holds one "profile=unit unit ..." line per profile, units
# listed dependents first (stop order). Start and resume use the reverse order.
# MEDIA_UNIT_PREFIX / MEDIA_CTR_PREFIX prefix the systemd unit and podman
# container name of a service.

usage() {
  cat <<USAGE
Usage: media-ctl <action> <target>...
       media-ctl list

Actions:
  stop      stop the containers (systemd units)
  start     start them (and rerun their media-<name>-config unit)
  restart   stop, then start
  pause     freeze the containers in place (podman pause); sockets and
            sessions stay open but nothing runs, uploads/downloads halt
  resume    unfreeze paused containers
  status    show systemd and container state

Targets: a profile or a single service name (see 'media-ctl list').
USAGE
}

declare -A PROFILE
PROFILE_ORDER=()
while IFS='=' read -r key value; do
  [[ -z $key ]] && continue
  PROFILE[$key]=$value
  PROFILE_ORDER+=("$key")
done <<<"$MEDIA_PROFILES"

# Every service that appears in some profile is also a valid target.
declare -A KNOWN
for p in "${PROFILE_ORDER[@]}"; do
  for s in ${PROFILE[$p]}; do
    KNOWN[$s]=1
  done
done

list() {
  local p
  echo "Profiles:"
  for p in "${PROFILE_ORDER[@]}"; do
    printf '  %-12s %s\n' "$p" "${PROFILE[$p]}"
  done
  echo
  echo "Services: ${!KNOWN[*]}"
}

# resolve TARGET...: prints unit names, dependents first, without duplicates.
resolve() {
  local t s
  declare -A seen=()
  for t in "$@"; do
    if [[ -n ${PROFILE[$t]+x} ]]; then
      for s in ${PROFILE[$t]}; do
        [[ -n ${seen[$s]+x} ]] || { seen[$s]=1; echo "$s"; }
      done
    elif [[ -n ${KNOWN[$t]+x} ]]; then
      [[ -n ${seen[$t]+x} ]] || { seen[$t]=1; echo "$t"; }
    else
      echo "media-ctl: unknown target '$t' (try 'media-ctl list')" >&2
      return 1
    fi
  done
}

unit() { echo "${MEDIA_UNIT_PREFIX}$1.service"; }
ctr() { echo "${MEDIA_CTR_PREFIX}$1"; }

# Containers that are up and not already paused/stopped.
running() { [[ $(podman inspect -f '{{.State.Status}}' "$(ctr "$1")" 2>/dev/null) == running ]]; }
paused() { [[ $(podman inspect -f '{{.State.Status}}' "$(ctr "$1")" 2>/dev/null) == paused ]]; }

[[ $# -ge 1 ]] || { usage; exit 1; }
action=$1
shift

case $action in
  list) list; exit 0 ;;
  -h | --help | help) usage; exit 0 ;;
esac

[[ $# -ge 1 ]] || { usage >&2; exit 1; }

if [[ $EUID -ne 0 ]]; then
  exec sudo -- "$0" "$action" "$@"
fi

resolved=$(resolve "$@") || exit 1
mapfile -t services <<<"$resolved"
reversed=()
for ((i = ${#services[@]} - 1; i >= 0; i--)); do
  reversed+=("${services[i]}")
done

case $action in
  stop)
    for s in "${services[@]}"; do
      echo "stop $s"
      systemctl stop "$(unit "$s")"
    done
    ;;
  start)
    for s in "${reversed[@]}"; do
      echo "start $s"
      systemctl start "$(unit "$s")"
      # The bootstrap unit is only PartOf the container: stop propagates, start
      # does not. Absent for services without one.
      if systemctl cat "media-$s-config.service" >/dev/null 2>&1; then
        systemctl start --no-block "media-$s-config.service"
      fi
    done
    ;;
  restart)
    for s in "${services[@]}"; do
      echo "stop $s"
      systemctl stop "$(unit "$s")"
    done
    for s in "${reversed[@]}"; do
      echo "start $s"
      systemctl start "$(unit "$s")"
    done
    ;;
  pause)
    for s in "${services[@]}"; do
      if running "$s"; then
        echo "pause $s"
        podman pause "$(ctr "$s")" >/dev/null
      else
        echo "skip $s (not running)"
      fi
    done
    ;;
  resume)
    for s in "${reversed[@]}"; do
      if paused "$s"; then
        echo "resume $s"
        podman unpause "$(ctr "$s")" >/dev/null
      else
        echo "skip $s (not paused)"
      fi
    done
    ;;
  status)
    printf '%-16s %-12s %s\n' SERVICE UNIT CONTAINER
    for s in "${services[@]}"; do
      u=$(systemctl is-active "$(unit "$s")" || true)
      c=$(podman inspect -f '{{.State.Status}}' "$(ctr "$s")" 2>/dev/null || echo -)
      printf '%-16s %-12s %s\n' "$s" "$u" "$c"
    done
    ;;
  *)
    echo "media-ctl: unknown action '$action'" >&2
    usage >&2
    exit 1
    ;;
esac
