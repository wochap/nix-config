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

echo "==> build"
nix eval --impure --json --expr '
  let
    pkgs = (builtins.getFlake "nixpkgs").legacyPackages.${builtins.currentSystem};
    set = import ./default.nix { inherit pkgs; };
  in
  map (n: set.${n}.drvPath) [ "greet" "greet-dev" "run-greet" ]' >/dev/null || exit 1

echo "==> test"
bash tests/run.sh || exit 1
