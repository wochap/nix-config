#!/usr/bin/env bash
set -euo pipefail

case "${1:-}" in
--version)
  printf 'greet %s\n' "${GREET_VERSION:?GREET_VERSION is not set}"
  ;;
--json)
  jq -cn --arg name "${2:-world}" '{greeting: ("Hello, " + $name + "!")}'
  ;;
*)
  printf 'Hello, %s!\n' "${1:-world}"
  ;;
esac
