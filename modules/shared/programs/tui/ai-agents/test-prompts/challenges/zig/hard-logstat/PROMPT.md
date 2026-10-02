# Log statistics library + CLI (Zig 0.16.0)

Implement module `logstat` in `src/root.zig` and the `logstat` executable in
`src/main.zig` (both wired up in `build.zig`). The stubs show every public name
the tests use; keep those names and signatures exactly.

## Log format

The input is text split on `\n`. Trim spaces, tabs and `\r` from both ends of
each line. Blank lines are ignored (not invalid). Every other line is either
valid or invalid:

- `LEVEL` is the text before the first space. It must be exactly one of
  `DEBUG`, `INFO`, `WARN`, `ERROR` (upper case).
- `source` is the text between that first space and the first `:` of the line,
  with spaces trimmed. It must be non-empty and contain no spaces or tabs.
- Anything after the `:` is the message and is ignored (it may be empty or contain `:`).
- A line with no space, no `:`, a `:` before the first space, a bad level, or a bad
  source is invalid.

Example: `WARN  cache : miss` is valid (level WARN, source `cache`);
`INFO bad source: x`, `TRACE api: x`, `INFO :x y` and `garbage` are invalid.

## API (`src/root.zig`)

```zig
pub const Level = enum { debug, info, warn, err };
pub const SourceCount = struct { name: []const u8, count: u32 };
pub const Summary = struct {
    levels: [4]u32 = .{ 0, 0, 0, 0 }, // count per level, index = @intFromEnum(Level)
    invalid: u32 = 0,                  // number of invalid lines
    sources: []SourceCount = &.{},     // valid lines per source
    pub fn deinit(self: *Summary, gpa: std.mem.Allocator) void;
    pub fn format(self: Summary, w: *std.Io.Writer) std.Io.Writer.Error!void;
};
pub fn parse(gpa: std.mem.Allocator, text: []const u8) !Summary;
pub fn summarizeFile(gpa: std.mem.Allocator, io: std.Io, dir: std.Io.Dir, sub_path: []const u8) !Summary;
pub fn writeReport(gpa: std.mem.Allocator, io: std.Io, dir: std.Io.Dir, in_path: []const u8, out_path: []const u8) !void;
```

- `sources` and every `name` in it are allocated with `gpa` and owned by the
  summary (`text` may be freed after `parse` returns); `deinit` frees them.
  `sources` is sorted by `count` descending, then `name` ascending (byte order).
- `parse` must not leak on any error, including `error.OutOfMemory` at any allocation.
- `format` (used as `{f}`) writes the first line, then one line per source:
  ```
  debug=<n> info=<n> warn=<n> error=<n> invalid=<n>
  <name> <count>
  ```
  Every line ends with `\n`.
- `summarizeFile` reads `sub_path` relative to `dir` and parses it. A file larger
  than 1 MiB (1048576 bytes) fails with `error.StreamTooLong`; a missing file
  fails with `error.FileNotFound`.
- `writeReport` summarizes `in_path` and writes the `format` output to `out_path`
  in `dir` (created or truncated).

## CLI (`zig-out/bin/logstat`)

- `logstat <file>`: summarize `<file>` (path relative to the current directory)
  and print the `format` output to stdout; exit 0.
- Wrong number of arguments: print `usage: logstat <file>` + newline to stderr; exit 2.
- Any error from reading/parsing: print `error: <ErrorName>` + newline to stderr
  (e.g. `error: FileNotFound`); exit 1.

Example: `tests/fixtures/app.log` must produce exactly `tests/fixtures/app.expected`.

Tests: `tests/logstat_test.zig` (`zig build test`) plus CLI checks in `check.sh`.
