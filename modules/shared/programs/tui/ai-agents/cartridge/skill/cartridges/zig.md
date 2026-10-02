# zig cartridge — target: Zig 0.16.0

## Rules (DON'T → DO)
- DON'T `pub fn main() !void` + build your own allocator/io → DO `pub fn main(init: std.process.Init) !void` and use `init.gpa`, `init.io`, `init.arena`
- DON'T `std.io.getStdOut().writer()` (std.io is gone) → DO `var fw: std.Io.File.Writer = .init(.stdout(), io, &buf);` then `&fw.interface`
- DON'T forget to flush a buffered writer → DO `try w.flush();` before exit
- DON'T `std.heap.GeneralPurposeAllocator(.{}){}` (removed) → DO `var da: std.heap.DebugAllocator(.{}) = .init;`
- DON'T `std.ArrayList(T).init(gpa)` → DO `var list: std.ArrayList(T) = .empty;`
- DON'T `list.append(x)` / `list.deinit()` → DO `list.append(gpa, x)` / `list.deinit(gpa)` (ArrayList is unmanaged)
- DON'T `std.fs.cwd()` / `std.fs.File` (removed) → DO `std.Io.Dir.cwd()` / `std.Io.File`
- DON'T `dir.openFile(path, .{})` → DO `dir.openFile(io, path, .{})`; almost every file/dir call now takes `io`
- DON'T `file.close()` → DO `file.close(io)`
- DON'T `std.time.sleep(ns)` / `std.Thread.sleep` (removed) → DO `try io.sleep(.fromMilliseconds(10), .awake);`
- DON'T `std.time.milliTimestamp()` / `std.time.Timer` (removed) → DO `std.Io.Timestamp.now(io, .awake)` and `.untilNow(io, .awake)`
- DON'T `std.process.argsAlloc` / `std.process.args()` (removed) → DO `try init.minimal.args.toSlice(arena)`
- DON'T `std.posix.getenv` / `std.process.getEnvVarOwned` (removed) → DO `init.environ_map.get("HOME")`
- DON'T `std.Thread.Mutex` (removed) → DO `var m: std.Io.Mutex = .init;` with `m.lockUncancelable(io)` / `m.unlock(io)`
- DON'T `std.Thread.Pool` (removed) → DO `std.Io.Group` with `g.async(io, f, .{args})` then `try g.await(io)`
- DON'T `std.crypto.random` → DO `io.random(&bytes)` to seed `std.Random.DefaultPrng`
- DON'T `std.json.stringify` (removed) → DO `std.json.fmt(value, .{})` with `{f}`, or `std.json.Stringify`
- DON'T `std.BoundedArray` (removed) → DO a fixed array + len, or `ArrayList` with `initCapacity`
- DON'T `std.mem.split` / `std.mem.tokenize` (removed) → DO `splitScalar`, `splitSequence`, `splitAny`, `tokenizeScalar`, `tokenizeAny`
- DON'T `std.mem.indexOf` / `indexOfScalar` (deprecated) → DO `std.mem.find` / `std.mem.findScalar`
- DON'T `usingnamespace` (removed) → DO explicit `pub const x = other.x;`
- DON'T `async`/`await`/`suspend` keywords → DO `io.async(func, .{args})` returning a Future, then `fut.await(io)`
- DON'T `@intCast(x)` with no result type → DO `const y: u16 = @intCast(x);` or `@as(u16, @intCast(x))`
- DON'T `print("{}", .{slice})` for strings → DO `{s}`; use `{any}` for arbitrary slices
- DON'T `{}` for a type with a `format` method (it is silently ignored) → DO `{f}`
- DON'T old format signature `format(self, comptime fmt, options, writer)` → DO `pub fn format(self: T, w: *std.Io.Writer) std.Io.Writer.Error!void`
- DON'T `.root_source_file` on `addExecutable` → DO `.root_module = b.createModule(.{ ... })`

## Gotchas
- `std.Io` is the single I/O interface: files, sleep, time, mutex, random, process spawn all need an `io: Io` value.
- In `main(init)`, `init.gpa` is a leak-checking DebugAllocator in Debug builds; leaks are reported, not fatal.
- `init.arena` is `*std.heap.ArenaAllocator`; call `.allocator()` on it.
- `std.Io.Writer` / `std.Io.Reader` are non-generic interfaces; buffers belong to the interface, not the stream.
- Take `&fw.interface` once and reuse it; never copy the `interface` field by value (it uses @fieldParentPtr).
- `std.debug.print` writes to stderr, unbuffered, and cannot fail; use it for quick debugging only.
- Unused locals and unused params are compile errors; use `_ = x;`.
- `var` that is never mutated is a compile error; use `const`.
- `defer` runs at scope exit in reverse order; `errdefer` runs only when the scope returns an error.
- Slices `[]T` carry a length; `[*]T` many-pointers do not; `*[N]T` coerces to `[]T`.
- String literals are `*const [N:0]u8`; take them as `[]const u8` params.
- `readFileAlloc` takes a limit: `.limited(n)` or `.unlimited`; it errors with `StreamTooLong`.
- `takeDelimiter('\n')` returns `?[]u8` (null at EOF) and the slice is only valid until the next read.
- Integer overflow panics in Debug/ReleaseSafe; use `+%` (wrap) or `+|` (saturate) when intended.
- `std.StringHashMap` does not copy keys; keys must outlive the map.
- `catch unreachable` on a real error is UB in ReleaseFast; prefer `try` or handle it.
- `std.process.exit` skips `defer`; return from main instead.

## Correct API names
- `std.io` → `std.Io`
- `std.fs.cwd()` → `std.Io.Dir.cwd()`
- `std.fs.File` → `std.Io.File`; stdio: `std.Io.File.stdout()`, `.stderr()`, `.stdin()`
- `std.heap.GeneralPurposeAllocator` → `std.heap.DebugAllocator`
- `std.ArrayListUnmanaged` (deprecated alias) → `std.ArrayList`; managed version is `std.array_list.Managed`
- `std.AutoArrayHashMapUnmanaged` (deprecated) → `std.array_hash_map.Auto`
- `std.StringArrayHashMapUnmanaged` (deprecated) → `std.array_hash_map.String`
- `std.time.sleep` → `io.sleep(duration, clock)`
- `std.mem.indexOf` → `std.mem.find`; `lastIndexOf` → `findLast`; `indexOfScalar` → `findScalar`
- `std.fmt.format(writer, ...)` (removed) → `writer.print(fmt, args)`
- `std.io.fixedBufferStream` → `std.Io.Writer.fixed(&buf)` / `std.Io.Reader.fixed(bytes)`
- `std.ArrayList(u8).writer()` → `std.Io.Writer.Allocating` (`.init(gpa)`, `.writer`, `.written()`)
- `std.ChildProcess` → `std.process.Child`; one-shot: `std.process.run(gpa, io, .{ .argv = &.{...} })`
- Error name in format: `{t}` or `@errorName(err)`

## Idioms
```zig
pub fn main(init: std.process.Init) !void {
    const gpa = init.gpa;
    const io = init.io;
    var buf: [1024]u8 = undefined;
    var fw: std.Io.File.Writer = .init(.stdout(), io, &buf);
    const out = &fw.interface;
    try out.print("hi {s}\n", .{"zig"});
    try out.flush();
}
```
```zig
var list: std.ArrayList(u32) = .empty;
defer list.deinit(gpa);
try list.append(gpa, 1);
for (list.items, 0..) |v, i| std.debug.print("{d}:{d}\n", .{ i, v });
for (0..10) |i| _ = i;
```
```zig
var map: std.StringHashMapUnmanaged(u32) = .empty;
defer map.deinit(gpa);
try map.put(gpa, "a", 1);
if (map.get("a")) |v| std.debug.print("{d}\n", .{v});
```
```zig
const data = try std.Io.Dir.cwd().readFileAlloc(io, "in.txt", gpa, .limited(1 << 20));
defer gpa.free(data);
var it = std.mem.splitScalar(u8, data, '\n');
while (it.next()) |line| _ = line;
```
```zig
const f = try std.Io.Dir.cwd().openFile(io, "in.txt", .{});
defer f.close(io);
var rbuf: [4096]u8 = undefined;
var fr = f.reader(io, &rbuf);
while (try fr.interface.takeDelimiter('\n')) |line| _ = line;
```
```zig
var da: std.heap.DebugAllocator(.{}) = .init; // when not using init.gpa
defer _ = da.deinit();
var arena = std.heap.ArenaAllocator.init(da.allocator());
defer arena.deinit();
```
```zig
const n: u16 = @intCast(big);
const fl: f32 = @floatFromInt(n);
const t = @as(u8, @truncate(big));
```

## Tooling
- `zig init` — scaffold build.zig, build.zig.zon, src/main.zig, src/root.zig
- `zig build` / `zig build run -- args` / `zig build test`
- `zig run file.zig` / `zig test file.zig` for single files
- `zig build -Doptimize=ReleaseFast` (also `ReleaseSafe`, `ReleaseSmall`)
- `zig fmt .` / `zig fmt --check .`
- `zig fetch --save <url>` to add a dependency to build.zig.zon
- `zig env` shows `lib_dir`; grep `<lib_dir>/std` to confirm an API before using it
- Minimal build.zig: `b.addExecutable(.{ .name = "app", .root_module = b.createModule(.{ .root_source_file = b.path("src/main.zig"), .target = target, .optimize = optimize }) })`, then `b.installArtifact(exe)`
