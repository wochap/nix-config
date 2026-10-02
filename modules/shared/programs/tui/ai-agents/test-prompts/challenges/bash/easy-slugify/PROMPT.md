# Bash: slugify

Write `slugify.sh`, a bash script run as `bash slugify.sh TEXT...`.

- All arguments are joined with a single space into one text.
- ASCII uppercase letters become lowercase.
- Every run of characters that are not `a-z` or `0-9` (after lowercasing) becomes one `-`.
  Non-ASCII characters count as "not a-z/0-9".
- No leading or trailing `-`.
- Print the slug followed by a newline to stdout and exit 0.
- If the slug is empty, print nothing and exit 1.
- With no arguments, print a line containing `usage` to stderr and exit 2.
- Arguments are data only: characters like `*`, `?`, `$`, `\` must never be expanded or interpreted.

Examples:

```console
$ bash slugify.sh "Hello, World!"
hello-world
$ bash slugify.sh "  --Already--slugged--  "
already-slugged
$ bash slugify.sh Foo "Bar  Baz"
foo-bar-baz
$ bash slugify.sh "C++ & Rust 2024"
c-rust-2024
$ bash slugify.sh '***'; echo $?
1
```

Tests: `bats tests/` (bats-core), run with `LC_ALL=C`.
The script must pass `shellcheck` and `shfmt -d -i 2 -ci`.
