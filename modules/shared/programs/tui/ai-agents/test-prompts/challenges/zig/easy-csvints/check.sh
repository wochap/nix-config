#!/usr/bin/env bash
set -uo pipefail
# Keep zig caches inside the workdir (no network, writable).
export ZIG_GLOBAL_CACHE_DIR="$PWD/.zig-global-cache" ZIG_LOCAL_CACHE_DIR="$PWD/.zig-cache"

echo "==> format"
if ! zig fmt --check build.zig src tests; then
  echo "run: zig fmt build.zig src"
  exit 1
fi

echo "==> build"
zig build || exit 1

echo "==> test"
zig build test --summary all || exit 1
