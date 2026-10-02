#!/usr/bin/env bash
set -uo pipefail

echo "==> format"
if ! stylua --check .; then
  echo "run: stylua ."
  exit 1
fi

echo "==> lint"
luacheck --no-color . || exit 1

echo "==> build"
luajit -e 'assert(loadfile("split.lua"))' || exit 1

echo "==> test"
luajit tests/run.lua || exit 1
