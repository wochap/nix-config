#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

setup() {
  script="$BATS_TEST_DIRNAME/../slugify.sh"
  cd "$BATS_TEST_TMPDIR" || exit 1
}

slug() {
  run --separate-stderr bash "$script" "$@"
}

@test "punctuation and case" {
  slug "Hello, World!"
  [ "$status" -eq 0 ]
  [ "$output" = "hello-world" ]
}

@test "leading and trailing separators are trimmed" {
  slug "  --Already--slugged--  "
  [ "$status" -eq 0 ]
  [ "$output" = "already-slugged" ]
}

@test "arguments are joined with a space" {
  slug Foo "Bar  Baz"
  [ "$status" -eq 0 ]
  [ "$output" = "foo-bar-baz" ]
}

@test "symbols collapse into one dash" {
  slug "C++ & Rust 2024"
  [ "$status" -eq 0 ]
  [ "$output" = "c-rust-2024" ]
}

@test "digits are kept" {
  slug "v1.2.3"
  [ "$status" -eq 0 ]
  [ "$output" = "v1-2-3" ]
}

@test "already a slug is unchanged" {
  slug "abc-123-xyz"
  [ "$status" -eq 0 ]
  [ "$output" = "abc-123-xyz" ]
}

@test "non-ASCII bytes are separators" {
  slug $'na\xc3\xafve caf\xc3\xa9'
  [ "$status" -eq 0 ]
  [ "$output" = "na-ve-caf" ]
}

@test "tabs and newlines are separators" {
  slug $'one\ttwo\nthree'
  [ "$status" -eq 0 ]
  [ "$output" = "one-two-three" ]
}

@test "glob characters are not expanded" {
  touch alpha beta
  slug "*"
  [ "$status" -eq 1 ]
  [ "$output" = "" ]
  slug "a*b?c"
  [ "$status" -eq 0 ]
  [ "$output" = "a-b-c" ]
}

@test "dollar and backslash are data" {
  slug 'cost $HOME \n 5'
  [ "$status" -eq 0 ]
  [ "$output" = "cost-home-n-5" ]
}

@test "option-like input" {
  slug "-n"
  [ "$status" -eq 0 ]
  [ "$output" = "n" ]
  slug "-e" "--x"
  [ "$status" -eq 0 ]
  [ "$output" = "e-x" ]
}

@test "only symbols gives exit 1 and no output" {
  slug '***'
  [ "$status" -eq 1 ]
  [ "$output" = "" ]
}

@test "empty argument gives exit 1" {
  slug ""
  [ "$status" -eq 1 ]
  [ "$output" = "" ]
}

@test "no arguments prints usage to stderr and exits 2" {
  slug
  [ "$status" -eq 2 ]
  [ "$output" = "" ]
  [[ "$stderr" == *usage* ]]
}

@test "long input" {
  long=$(printf 'Ab-%.0s' {1..200})
  slug "$long"
  [ "$status" -eq 0 ]
  [ "${#output}" -eq 599 ]
  [[ "$output" == ab-ab-* ]]
  [[ "$output" != *- ]]
}
