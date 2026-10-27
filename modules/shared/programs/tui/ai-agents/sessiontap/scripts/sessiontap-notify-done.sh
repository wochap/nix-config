#!/usr/bin/env bash

set -Eeuo pipefail

readonly sound_file=/nix/store/ydg46632kcwa5zg0zb5pynr07rnhf1am-sound-theme-freedesktop-0.8/share/sounds/freedesktop/stereo/phone-outgoing-busy.oga
readonly debounce_seconds=5

floor=0

usage() {
  cat <<'EOF'
Usage: sessiontap-notify-done [OPTIONS]

Play an alarm when the number of active agents reaches or falls below a floor.

Options:
  -f, --floor N    Alarm when active agent count <= N (default: 0)
  -h, --help       Show this help

Examples:
  sessiontap-notify-done
      Alarm when no active agents remain.

  sessiontap-notify-done --floor 1
      Alarm when fewer than 2 active agents remain.

  sessiontap-notify-done -f 2
      Alarm when 2 or fewer active agents remain.
EOF
}

while (($# > 0)); do
  case "$1" in
  -f | --floor)
    if (($# < 2)); then
      printf 'sessiontap-notify-done: %s requires a value\n' "$1" >&2
      exit 2
    fi

    floor=$2
    shift 2
    ;;

  --floor=*)
    floor=${1#*=}
    shift
    ;;

  -h | --help)
    usage
    exit 0
    ;;

  *)
    printf 'sessiontap-notify-done: unknown option: %s\n' "$1" >&2
    usage >&2
    exit 2
    ;;
  esac
done

if [[ ! "$floor" =~ ^[0-9]+$ ]]; then
  printf 'sessiontap-notify-done: floor must be a non-negative integer\n' >&2
  exit 2
fi

declare -A agents=()

active_count() {
  local status count=0

  for status in "${agents[@]}"; do
    case "$status" in
    running | blocked | idle)
      ((count += 1))
      ;;
    esac
  done

  printf '%d\n' "$count"
}

at_or_below_floor() {
  local count=$1
  ((count <= floor))
}

apply_envelope() {
  local envelope=$1 type source_id invocation_id status key

  type=$(jq -r '.type // empty' <<<"$envelope") || return 1

  case "$type" in
  snapshot)
    jq -e '.agents | type == "array"' >/dev/null 2>&1 <<<"$envelope" || return 1
    agents=()

    while IFS=$'\t' read -r source_id invocation_id status; do
      [[ -n "$source_id" && -n "$invocation_id" ]] || continue
      [[ "$status" == "stopped" ]] && continue

      agents["$source_id:$invocation_id"]=$status
    done < <(
      jq -r '
        .agents[]
        | select(.view | type == "object")
        | [(.source_id // ""), (.view.invocation_id // ""), (.view.status // "")]
        | @tsv
      ' <<<"$envelope"
    )
    ;;

  update)
    IFS=$'\t' read -r source_id invocation_id status < <(
      jq -r '
        select(.view | type == "object")
        | [(.source_id // ""), (.view.invocation_id // ""), (.view.status // "")]
        | @tsv
      ' <<<"$envelope"
    )

    [[ -n "$source_id" && -n "$invocation_id" ]] || return 1

    key="$source_id:$invocation_id"

    if [[ "$status" == "stopped" ]]; then
      unset 'agents[$key]'
    else
      agents["$key"]=$status
    fi
    ;;

  *)
    return 1
    ;;
  esac
}

stop_listener() {
  trap - EXIT INT TERM
  kill "$listener_pid" 2>/dev/null || true
  wait "$listener_pid" 2>/dev/null || true
}

play_alarm() {
  stop_listener

  exec mpv \
    --no-config \
    --no-video \
    --no-terminal \
    --really-quiet \
    --audio-pitch-correction=yes \
    --volume=150 \
    --volume-max=150 \
    --loop-file=inf \
    "$sound_file"
}

coproc SESSIONTAP_LISTENER { exec sessiontap-hub listen; }

listener_pid=$SESSIONTAP_LISTENER_PID
listener_fd=${SESSIONTAP_LISTENER[0]}

trap stop_listener EXIT INT TERM

initialized=false
below_floor_since=

while true; do
  timeout=

  if [[ -n "$below_floor_since" ]]; then
    elapsed=$((SECONDS - below_floor_since))

    if ((elapsed >= debounce_seconds)); then
      # Consume updates that may have raced with the timeout.
      while IFS= read -r -t 0.05 envelope <&"$listener_fd"; do
        apply_envelope "$envelope" || continue
      done

      count=$(active_count)

      if at_or_below_floor "$count"; then
        play_alarm
      fi

      # Count moved back above the floor.
      below_floor_since=
      continue
    fi

    timeout=$((debounce_seconds - elapsed))
  fi

  if [[ -n "$timeout" ]]; then
    if ! IFS= read -r -t "$timeout" envelope <&"$listener_fd"; then
      if ! kill -0 "$listener_pid" 2>/dev/null; then
        printf 'sessiontap-notify-done: sessiontap-hub listener exited\n' >&2
        exit 1
      fi

      # Debounce expired. Re-check after consuming racing updates.
      while IFS= read -r -t 0.05 envelope <&"$listener_fd"; do
        apply_envelope "$envelope" || continue
      done

      count=$(active_count)

      if at_or_below_floor "$count"; then
        play_alarm
      fi

      below_floor_since=
      continue
    fi
  elif ! IFS= read -r envelope <&"$listener_fd"; then
    printf 'sessiontap-notify-done: sessiontap-hub listener exited\n' >&2
    exit 1
  fi

  apply_envelope "$envelope" || continue
  count=$(active_count)

  if [[ "$initialized" == false ]]; then
    initialized=true

    # Snapshot is only a baseline. Do not alarm merely because the
    # script was launched while already at/below the configured floor.
    if at_or_below_floor "$count"; then
      exit 0
    fi
  fi

  if at_or_below_floor "$count"; then
    [[ -z "$below_floor_since" ]] && below_floor_since=$SECONDS
  else
    below_floor_since=
  fi
done
