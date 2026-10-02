#!/usr/bin/env bash
set -uo pipefail
STYLE='{BasedOnStyle: LLVM, IndentWidth: 4, ColumnLimit: 100}'
SRCS=(src/*.cpp)
CXXFLAGS=(-std=c++23 -Wall -Wextra -Wpedantic -Werror -g -fsanitize=address,undefined -fno-omit-frame-pointer)

echo "==> format"
if ! clang-format --style="$STYLE" --dry-run -Werror src/*.cpp src/*.hpp; then
  echo "run: clang-format --style='$STYLE' -i src/*.cpp src/*.hpp"
  exit 1
fi

echo "==> lint"
tidy_out=$(clang-tidy --quiet --warnings-as-errors='*' \
  --checks='-*,bugprone-*,-bugprone-easily-swappable-parameters,modernize-use-nullptr,performance-*,readability-else-after-return' \
  "${SRCS[@]}" -- -std=c++23 -x c++ -Isrc 2>&1)
rc=$?
grep -v ' warnings generated\.$' <<<"$tidy_out"
((rc == 0)) || exit 1

echo "==> build"
mkdir -p build
g++ "${CXXFLAGS[@]}" -Isrc "${SRCS[@]}" tests/test.cpp -o build/test || exit 1

echo "==> test"
ASAN_OPTIONS=detect_leaks=1 UBSAN_OPTIONS=halt_on_error=1:print_stacktrace=1 ./build/test || exit 1
