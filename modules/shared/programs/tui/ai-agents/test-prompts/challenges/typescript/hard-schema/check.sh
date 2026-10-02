#!/usr/bin/env bash
set -uo pipefail

echo "==> format"
if ! biome format src tests; then
  echo "run: biome format --write src tests"
  exit 1
fi

echo "==> lint"
biome lint src tests || exit 1

echo "==> build"
tsc --noEmit -p tsconfig.json || exit 1

echo "==> test"
node --test tests/*.test.ts || exit 1
