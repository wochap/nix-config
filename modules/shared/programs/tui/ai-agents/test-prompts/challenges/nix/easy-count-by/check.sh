#!/usr/bin/env bash
set -uo pipefail

echo "==> format"
if ! nixfmt --check ./*.nix tests/*.nix; then
  echo "run: nixfmt ./*.nix"
  exit 1
fi

echo "==> lint"
statix check -o errfmt . || exit 1
deadnix --fail . || exit 1

echo "==> test"
nix eval --impure --raw --expr 'import ./tests/test.nix' || exit 1
echo
