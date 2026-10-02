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

bin=./zig-out/bin/logstat
fail() { echo "FAIL: $*"; exit 1; }

out=$("$bin" tests/fixtures/app.log 2>.logstat-err); code=$?
[[ $code -eq 0 ]] || fail "logstat tests/fixtures/app.log exited $code (stderr: $(cat .logstat-err))"
diff -u tests/fixtures/app.expected <(printf '%s\n' "$out") || fail "stdout differs from tests/fixtures/app.expected"

err=$("$bin" 2>&1 >/dev/null); code=$?
[[ $code -eq 2 ]] || fail "logstat with no args exited $code, want 2"
[[ "$err" == "usage: logstat <file>" ]] || fail "logstat with no args stderr = '$err', want 'usage: logstat <file>'"

err=$("$bin" a b 2>&1 >/dev/null); code=$?
[[ $code -eq 2 ]] || fail "logstat with 2 args exited $code, want 2"

err=$("$bin" tests/fixtures/missing.log 2>&1 >/dev/null); code=$?
[[ $code -eq 1 ]] || fail "logstat on missing file exited $code, want 1"
[[ "$err" == "error: FileNotFound" ]] || fail "logstat on missing file stderr = '$err', want 'error: FileNotFound'"
rm -f .logstat-err
echo "cli ok"
