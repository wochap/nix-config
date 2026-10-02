# Parse integer list (Zig 0.16.0)

Implement `parseInts` in `src/root.zig` (module `csvints`, built by `build.zig`):

```zig
pub const ParseError = error{InvalidNumber};

pub fn parseInts(gpa: std.mem.Allocator, line: []const u8) (ParseError || std.mem.Allocator.Error)![]i64
```

- `line` is a comma-separated list of base-10 `i64` values.
- Trim spaces and tabs around each field. An optional leading `+` or `-` is allowed.
- Skip fields that are empty after trimming.
- Any other field that is not a valid `i64` (bad characters, out of range) →
  `error.InvalidNumber`.
- Return a slice allocated with `gpa`; the caller frees it with `gpa.free`.
  On error, nothing may leak (tests use `std.testing.allocator`).

Examples:

```
"1,2,3"          -> {1, 2, 3}
" 10 ,\t-20,+30" -> {10, -20, 30}
",,5,, ,6,"      -> {5, 6}
""               -> {}
"1,x,3"          -> error.InvalidNumber
```

Tests: `tests/csvints_test.zig` (run by `zig build test`). Run `bash check.sh`.
