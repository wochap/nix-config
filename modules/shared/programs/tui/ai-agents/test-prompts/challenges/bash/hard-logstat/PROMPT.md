# Bash: logstat

Write `logstat.sh`, a bash (5.3) script that summarizes web access logs.

```
bash logstat.sh [-n N] [-s CLASS] [-f FORMAT] [--] [FILE...]
```

## Input

Each log line has 5 whitespace-separated fields: `IP METHOD PATH STATUS BYTES`, e.g.
`10.0.0.1 GET /index.html 200 512`.

- Lines that are empty, only whitespace, or whose first non-space character is `#` are ignored.
- A line is malformed if it does not have exactly 5 fields, `STATUS` is not 3 digits starting
  with `1`-`5`, or `BYTES` is not a non-negative integer or `-`. Malformed lines are skipped;
  if any were skipped, print `logstat: skipped <N> malformed line(s)` to stderr (exit code stays 0).
- `BYTES` of `-` counts as 0. Numbers like `0010` are decimal (10).
- `PATH` is arbitrary text without whitespace (may contain `* ? [ ] $ ( ) ' " \ & < >` etc.).
  It is data only: never expanded, evaluated or interpreted.
- Files are read in the given order. No files, or a file named `-`, means stdin.
  The last line of a file may lack a trailing newline. File names may contain spaces.

## Options

- `-n N`, `--top N`: show only the top `N` paths (default 10). `N` must be a positive integer.
- `-s CLASS`, `--status CLASS`: `CLASS` is one of `1xx` `2xx` `3xx` `4xx` `5xx`; only lines with a
  status in that class are counted (also in the totals).
- `-f FORMAT`, `--format FORMAT`: `text` (default), `json` or `html`.
- `--` ends options; everything after it is a file name.
- Unknown option, missing/invalid option value: print a line containing `usage` to stderr, exit 2.
- A file that does not exist or is not readable: print `logstat: cannot read <FILE>` to stderr,
  print nothing to stdout, exit 1. Check all files before reading any.

## Output

Per path: `count` (number of counted lines) and `bytes` (sum). Paths are ranked by count
descending, then by path in byte order ascending (like `LC_ALL=C sort`). Totals cover all counted
lines, not only the top `N`.

`text`: one line per ranked path `<count> <bytes> <path>`, then `TOTAL <requests> <bytes>`:
```
3 1536 /index.html
1 0 /favicon.ico
TOTAL 4 1536
```

`json`: a single line, no spaces, path strings escaped for JSON (`"` → `\"`, `\` → `\\`):
```
{"total":{"requests":4,"bytes":1536},"paths":[{"path":"/index.html","count":3,"bytes":1536},{"path":"/favicon.ico","count":1,"bytes":0}]}
```
With no counted lines: `{"total":{"requests":0,"bytes":0},"paths":[]}`.

`html`: in each path replace `&` → `&amp;`, `<` → `&lt;`, `>` → `&gt;`, `"` → `&quot;`:
```
<table>
<tr><th>path</th><th>count</th><th>bytes</th></tr>
<tr><td>/a?x=1&amp;y=&lt;2&gt;</td><td>3</td><td>1536</td></tr>
</table>
```

Tests: `bats tests/` (bats-core). The script must pass `shellcheck` and `shfmt -d -i 2 -ci`.
