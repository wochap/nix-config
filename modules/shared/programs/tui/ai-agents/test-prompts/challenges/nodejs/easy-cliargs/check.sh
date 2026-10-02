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
for f in src/*.js; do
  node --check "$f" || exit 1
done

echo "==> test"
node --test tests/*.test.js || exit 1
