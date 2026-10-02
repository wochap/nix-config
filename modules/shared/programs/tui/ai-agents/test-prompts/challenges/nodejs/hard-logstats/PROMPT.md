# Log statistics

Build a small log analyzer for Node.js 24 (ES modules, standard library only,
no npm packages).

## Log format
A log directory contains files at any depth. Only files whose name ends in
`.log` (plain text) or `.log.gz` (gzip-compressed text) are logs; ignore all
other files. Each line of a log is one JSON object:

```json
{"level":"info","msg":"started","ms":12}
```

A line is a valid entry when it parses as a JSON object with `level` one of
`"info"`, `"warn"`, `"error"`, `msg` a string, and `ms` a finite number.
Empty or whitespace-only lines are skipped and not counted. Every other line
is invalid. Lines may end with `\n` or `\r\n`. Files can be large: do not
load a whole file into memory at once.

## `src/logstats.js`

### `summarizeDir(dir)` (async)
Resolves to:
```js
{
  files: 3,        // number of log files found
  entries: 10,     // number of valid entries
  invalid: 2,      // number of invalid lines
  levels: { info: 6, warn: 3, error: 1 }, // always all three keys
  maxMs: 120,      // largest ms, or null when there are no entries
  slowest: [       // up to 3 entries, ms descending, ties by file then line
    { file: "api/a.log.gz", line: 4, ms: 120, msg: "slow query" },
  ],
}
```
`file` is the path relative to `dir`, always with `/` separators; `line` is
the 1-based line number inside that file (blank lines count for numbering).
Rejects (with the underlying error) when `dir` does not exist.

### `writeReport(summary, outPath)` (async)
Writes `JSON.stringify(summary, null, 2)` plus a trailing newline to
`outPath`, creating missing parent directories. The write must be atomic:
write a temporary file in the same directory, then rename it over `outPath`.
No temporary files may remain afterwards.

## `src/cli.js`
```
node src/cli.js [--out <file> | -o <file>] <dir>
```
- Without `--out`, prints the summary to stdout as
  `JSON.stringify(summary, null, 2)` plus a newline.
- With `--out`, writes it with `writeReport` and prints nothing.
- On any error (missing or extra arguments, unknown option, missing
  directory) prints one line `error: <message>` to stderr and exits with
  code 2. Exit code 0 on success.

Files: `src/logstats.js`, `src/cli.js`. Tests live in `tests/` and run with
`node --test`.
