#!/usr/bin/env bash
set -uo pipefail

echo "==> format"
if ! shfmt -d -i 2 -ci slugify.sh; then
  echo "run: shfmt -w -i 2 -ci slugify.sh"
  exit 1
fi

echo "==> lint"
shellcheck slugify.sh || exit 1

echo "==> build"
bash -n slugify.sh || exit 1

echo "==> test"
LC_ALL=C bats tests/ || exit 1
