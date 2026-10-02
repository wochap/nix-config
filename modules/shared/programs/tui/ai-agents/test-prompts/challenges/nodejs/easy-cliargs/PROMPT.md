# CLI argument parser

Implement `src/cli.js` (Node.js 24, ES module) exporting:

```js
export function parseCli(argv) // argv: string[] without the node/script path
// returns { name: string, count: number, verbose: boolean, files: string[] }
```

Options:

| option | short | value | default |
|---|---|---|---|
| `--name <text>` | `-n` | string | `"world"` |
| `--count <n>` | `-c` | positive integer | `1` |
| `--verbose` | `-v` | flag; `--no-verbose` turns it off | `false` |

- Accept the usual forms: `--name bob`, `--name=bob`, `-n bob`, `-c3`,
  grouped short flags like `-vn bob`. When an option repeats, the last one wins.
- Every non-option argument goes to `files`, in order. Everything after `--`
  is a file, even if it starts with `-`.
- Unknown options, a missing value (`--name` at the end), or a value given to
  `--verbose` throw a `TypeError`.
- `count` must be written as decimal digits only and be at least 1
  (`"0"`, `"-2"`, `"1.5"`, `"abc"`, `"1e3"` are invalid): throw a `RangeError`.

```js
parseCli([])                          // { name: "world", count: 1, verbose: false, files: [] }
parseCli(["-vn", "bob", "a.txt"])     // { name: "bob", count: 1, verbose: true, files: ["a.txt"] }
parseCli(["--count=3", "--", "-x"])   // { name: "world", count: 3, verbose: false, files: ["-x"] }
```

Use only Node's standard library (no npm packages).
Files: `src/cli.js`. Tests live in `tests/` and run with `node --test`.
