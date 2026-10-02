# bash cartridge — target: GNU bash 5.3

## Rules (DON'T → DO)
- DON'T `#!/bin/bash` (absent on NixOS) → DO `#!/usr/bin/env bash`
- DON'T leave expansions unquoted (`$var`, `$(cmd)`) → DO quote: `"$var"`, `"$(cmd)"`
- DON'T use backticks → DO use `$(...)`
- DON'T use `[ ]` / `test` → DO use `[[ ]]` (no word splitting, supports `=~`, `&&`)
- DON'T use `$*` or `${arr[*]}` to pass args → DO use `"$@"` and `"${arr[@]}"`
- DON'T `for f in $(ls *.txt)` → DO `for f in *.txt; do [[ -e $f ]] || continue; ...`
- DON'T `for line in $(cat file)` → DO `while IFS= read -r line; do ...; done < file`
- DON'T `read line` → DO `read -r line` (without -r backslashes are eaten)
- DON'T `cmd | while read ...` when you need vars after → DO `while ...; done < <(cmd)`
- DON'T `echo "$var"` for arbitrary data / escapes → DO `printf '%s\n' "$var"`
- DON'T `echo -e` → DO `printf` with format string
- DON'T build commands in a string and `eval` → DO build an array: `cmd=(git log); "${cmd[@]}"`
- DON'T `cd dir` without a check → DO `cd dir || exit 1`
- DON'T `local x=$(cmd)` when you need the exit code → DO `local x; x=$(cmd)`
- DON'T `which foo` → DO `command -v foo >/dev/null`
- DON'T `expr` / `let` → DO `(( n += 1 ))` and `$(( a * b ))`
- DON'T `function f() {` → DO `f() {`
- DON'T parse `ls` output → DO use globs or `find ... -print0 | while IFS= read -r -d '' f`
- DON'T use `mktemp` without cleanup → DO `tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT`

## Gotchas
- `set -e` is ignored inside functions called from `if`, `&&`, `||`, `!` contexts.
- `set -e` does not exit on failure in `$(...)` inside `local`/`export`/`declare` (their status wins).
- `inherit_errexit` is off: `$(...)` subshells do not inherit `set -e`; add `shopt -s inherit_errexit`.
- `(( i++ ))` returns 1 when the old value is 0, which kills a `set -e` script; use `(( i += 1 ))` or `i=$((i + 1))`.
- `set -u` errors on unset vars: use `"${1:-}"`, `"${VAR:-default}"`. Empty arrays `"${a[@]}"` are fine in 5.x.
- `set -o pipefail`: `cmd | head -1` may fail with SIGPIPE (141) from `cmd`.
- `grep` exits 1 on no match; under `set -e` write `grep ... || true`.
- Pipelines run each part in a subshell: vars set in `| while` are lost (`lastpipe` only works with job control off).
- `[[ $a == $b ]]`: unquoted right side is a glob pattern; quote it for literal compare: `[[ $a == "$b" ]]`.
- `[[ $s =~ $re ]]`: keep the regex in a variable, unquoted; quoted regex is matched literally. Groups in `BASH_REMATCH`.
- `[[ ]]` compares numbers as strings with `<`/`>`; use `(( a < b ))` or `-lt`.
- `${var//pat/rep}`: in 5.2+ `&` in rep means the matched text (`patsub_replacement`); escape `\&` or quote it.
- `read` without `IFS=` strips leading/trailing whitespace.
- Last line without trailing newline is skipped by `while read`; use `|| [[ -n $line ]]`.
- `trap ... EXIT` runs on normal exit and on `set -e` exit; add `INT TERM` if you need custom signal handling.
- Variables in functions are global unless declared `local`.
- `$?` is reset by every command, including `[[ ]]` and `echo`; save it right away: `rc=$?`.
- `~` does not expand inside quotes: use `"$HOME/x"`.
- `source` of a file with `set -e` changes the caller's shell options.
- Associative arrays need `declare -A m` before use; `m[key]=v`, keys: `"${!m[@]}"`.
- `exit` inside `( ... )` or a pipeline only exits the subshell.
- bash 5.3: `${ cmd; }` captures output without a fork; `${| cmd; }` returns `$REPLY`. Not portable to older bash.

## Correct API names
- `mapfile -t arr < file` / `readarray -t` (same builtin); not `readlines`.
- `read -r -a arr <<< "$s"` splits a string into an array; `read -r -d ''` reads NUL-terminated.
- `printf -v var '%s' ...` assigns without a subshell; `printf '%(%F %T)T' -1` prints date without `date`.
- `declare -n ref=name` (nameref), `declare -g` (global from function), `declare -p var` (debug dump).
- `${#arr[@]}` length, `${!arr[@]}` indices, `${arr[-1]}` last, `${s:off:len}` substring.
- `${var#pre}` `${var##pre}` `${var%suf}` `${var%%suf}` strip; `${var^^}` / `${var,,}` case.
- `${var:?msg}` fail if unset/empty; `${var:+alt}` alt if set.
- `$EPOCHSECONDS`, `$EPOCHREALTIME`, `$SRANDOM`, `$BASHPID`, `${BASH_SOURCE[0]}`, `$FUNCNAME`, `$LINENO`.
- `wait -n` waits for any job; `wait "$pid"` returns its exit code.
- `getopts "ab:" opt` handles only short options; `OPTARG`, `OPTIND`; long opts need a manual `case` loop.
- `shopt -s nullglob globstar extglob`; `compgen -c`, `type -t name`.

## Idioms
```bash
#!/usr/bin/env bash
set -euo pipefail
shopt -s inherit_errexit nullglob
```
```bash
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
```
```bash
while getopts ":vo:" opt; do
  case $opt in v) verbose=1 ;; o) out=$OPTARG ;; *) usage; exit 2 ;; esac
done; shift $((OPTIND - 1))
```
```bash
die() { printf '%s\n' "$*" >&2; exit 1; }
```
```bash
while IFS= read -r -d '' f; do printf '%s\n' "$f"; done < <(find . -type f -print0)
```
```bash
if ! out=$(cmd 2>&1); then die "cmd failed: $out"; fi
```

## Tooling
- Lint: `shellcheck script.sh` (fix all warnings; disable inline with `# shellcheck disable=SC2086`)
- Format: `shfmt -w -i 2 -ci script.sh`; check only: `shfmt -d`
- Syntax check without running: `bash -n script.sh`; trace: `bash -x script.sh` or `set -x`
- Test: `bats test/` (bats-core)
- On Nix: `nix shell nixpkgs#shellcheck nixpkgs#shfmt`; `writeShellApplication` runs shellcheck at build time
