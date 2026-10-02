#!/usr/bin/env bash
set -uo pipefail
# No network: no external crates. Keep cargo state inside the workdir.
export CARGO_HOME="$PWD/.cargo-home" CARGO_NET_OFFLINE=true CARGO_TERM_COLOR=never

echo "==> format"
if ! cargo fmt --check; then
  echo "run: cargo fmt"
  exit 1
fi

echo "==> lint"
cargo clippy --offline --all-targets -- -D warnings || exit 1

echo "==> build"
cargo build --offline || exit 1

echo "==> test"
cargo test --offline || exit 1
