#!/usr/bin/env bash
# Builds the attributes from default.nix and runs them with an empty environment.
set -uo pipefail

fails=0
pass() { printf 'ok   %s\n' "$1"; }
fail() {
  printf 'FAIL %s\n' "$1"
  fails=$((fails + 1))
}
expect() { # name want got
  if [[ "$3" == "$2" ]]; then pass "$1"; else fail "$1: want $(printf '%q' "$2"), got $(printf '%q' "$3")"; fi
}

pkgs='(builtins.getFlake "nixpkgs").legacyPackages.${builtins.currentSystem}'
log=$(mktemp)
trap 'rm -f "$log"' EXIT
build() {
  if ! nix build --impure --no-link --print-out-paths --expr \
    "let pkgs = $pkgs; set = import ./default.nix { inherit pkgs; }; in $1" 2>"$log"; then
    tail -n 30 "$log" >&2
    return 1
  fi
}

nix eval --impure --raw --expr 'import ./tests/eval.nix { }' || exit 1
echo

greet=$(build 'set.greet') || {
  echo "FAIL build greet"
  exit 1
}
expect "greet Ann" "Hello, Ann!" "$(env -i "$greet/bin/greet" Ann 2>&1)"
expect "greet no args" "Hello, world!" "$(env -i "$greet/bin/greet" 2>&1)"
expect "greet --json" '{"greeting":"Hello, A \"q\"!"}' "$(env -i "$greet/bin/greet" --json 'A "q"' 2>&1)"
expect "greet --version" "greet 1.2.0" "$(env -i "$greet/bin/greet" --version 2>&1)"
expect "only bin/greet" "greet" "$(ls "$greet/bin" 2>&1)"

over=$(build 'set.greet.overrideAttrs { version = "9.9.9"; __intentionallyOverridingVersion = true; }') || {
  echo "FAIL build greet.overrideAttrs"
  exit 1
}
expect "overrideAttrs version" "greet 9.9.9" "$(env -i "$over/bin/greet" --version 2>&1)"

dev=$(build 'set.greet-dev') || {
  echo "FAIL build greet-dev"
  exit 1
}
expect "greet-dev --version" "greet 1.2.0-dev" "$(env -i "$dev/bin/greet" --version 2>&1)"

run=$(build 'set.run-greet') || {
  echo "FAIL build run-greet"
  exit 1
}
expect "hello-all is the only file" "hello-all" "$(ls "$run/bin" 2>&1)"
expect "hello-all two args" $'Hello, Ann!\nHello, Bo B!' "$(env -i "$run/bin/hello-all" Ann 'Bo B' 2>&1)"
expect "hello-all no args" "" "$(env -i "$run/bin/hello-all" 2>&1)"

if ((fails)); then
  echo "$fails test(s) failed"
  exit 1
fi
echo "all tests passed"
