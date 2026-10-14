#!/usr/bin/env bash
# Daily canary: run each search recipe with a fixed query and compare the number
# of rows against the expected snapshot. Any mismatch or failure sends a
# critical notification (a changed count usually means the site layout changed
# and the recipe selectors need healing).
#
# usage: webscoop-healthcheck <tolerance> <query> <recipe>=<expected-count>...

notify() {
  if command -v notify-send >/dev/null && [[ -n ${DBUS_SESSION_BUS_ADDRESS:-} ]]; then
    notify-send --app-name=webscoop --app-icon=dialog-warning "$@" || true
  fi
}

tolerance=${1:?usage: webscoop-healthcheck <tolerance> <query> <recipe>=<count>...}
query=${2:?usage: webscoop-healthcheck <tolerance> <query> <recipe>=<count>...}
shift 2

failures=()
for spec in "$@"; do
  recipe=${spec%%=*}
  expected=${spec#*=}

  if ! out=$(webscoop run "$recipe" --quiet --var "query=$query" 2>&1); then
    failures+=("$recipe: run failed")
    echo "[$recipe] run failed: $out" >&2
    continue
  fi
  if ! actual=$(jq 'if type == "array" then length else error("not an array") end' <<<"$out" 2>/dev/null); then
    failures+=("$recipe: invalid output")
    echo "[$recipe] invalid output: $out" >&2
    continue
  fi

  diff=$((actual - expected))
  if ((diff < 0)); then diff=$((-diff)); fi
  if ((diff <= tolerance)); then
    echo "[$recipe] ok: $actual results (expected $expected ±$tolerance)"
  else
    failures+=("$recipe: expected $expected ±$tolerance results, got $actual")
    echo "[$recipe] MISMATCH: expected $expected ±$tolerance, got $actual" >&2
  fi
done

if ((${#failures[@]} > 0)); then
  notify --urgency=critical "Webscoop healthcheck failed" "$(printf '%s\n' "${failures[@]}")"
  exit 1
fi
