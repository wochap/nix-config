const std = @import("std");
const logstat = @import("logstat");

const testing = std.testing;

fn render(s: logstat.Summary) ![]u8 {
    var aw: std.Io.Writer.Allocating = .init(testing.allocator);
    defer aw.deinit();
    try aw.writer.print("{f}", .{s});
    return aw.toOwnedSlice();
}

test "parse counts levels, sources and invalid lines" {
    const text =
        \\INFO api: started
        \\DEBUG db: connect
        \\ERROR db: timeout
        \\info api: lower-case level is invalid
        \\INFO api: second: colon is part of message
        \\
        \\WARN nocolon
        \\INFO   spaced  : ok
    ;
    var s = try logstat.parse(testing.allocator, text);
    defer s.deinit(testing.allocator);
    try testing.expectEqual([4]u32{ 1, 3, 0, 1 }, s.levels);
    try testing.expectEqual(@as(u32, 2), s.invalid);
    try testing.expectEqual(@as(usize, 3), s.sources.len);
    try testing.expectEqualStrings("api", s.sources[0].name);
    try testing.expectEqual(@as(u32, 2), s.sources[0].count);
    try testing.expectEqualStrings("db", s.sources[1].name);
    try testing.expectEqualStrings("spaced", s.sources[2].name);
}

test "level index matches enum" {
    var s = try logstat.parse(testing.allocator, "WARN a: x\nWARN b: y\nERROR a: z\n");
    defer s.deinit(testing.allocator);
    try testing.expectEqual(@as(u32, 2), s.levels[@intFromEnum(logstat.Level.warn)]);
    try testing.expectEqual(@as(u32, 1), s.levels[@intFromEnum(logstat.Level.err)]);
}

test "format output and tie ordering" {
    var s = try logstat.parse(testing.allocator, "INFO zeta: 1\nINFO alpha: 2\r\nERROR mid: 3\nINFO mid: 4\n\n");
    defer s.deinit(testing.allocator);
    const out = try render(s);
    defer testing.allocator.free(out);
    try testing.expectEqualStrings(
        "debug=0 info=3 warn=0 error=1 invalid=0\nmid 2\nalpha 1\nzeta 1\n",
        out,
    );
}

test "empty input" {
    var s = try logstat.parse(testing.allocator, "");
    defer s.deinit(testing.allocator);
    const out = try render(s);
    defer testing.allocator.free(out);
    try testing.expectEqualStrings("debug=0 info=0 warn=0 error=0 invalid=0\n", out);
}

test "source names are owned copies" {
    const buf = try testing.allocator.dupe(u8, "INFO owned: x\n");
    var s = try logstat.parse(testing.allocator, buf);
    defer s.deinit(testing.allocator);
    @memset(buf, 'X');
    testing.allocator.free(buf);
    try testing.expectEqualStrings("owned", s.sources[0].name);
}

test "no leaks when allocation fails" {
    const text = "INFO a: 1\nINFO b: 2\nINFO c: 3\nINFO d: 4\nINFO e: 5\nINFO f: 6\nINFO g: 7\nINFO h: 8\nINFO i: 9\n";
    var fail_index: usize = 0;
    while (fail_index < 64) : (fail_index += 1) {
        var fa = testing.FailingAllocator.init(testing.allocator, .{ .fail_index = fail_index });
        if (logstat.parse(fa.allocator(), text)) |summary| {
            var s = summary;
            s.deinit(fa.allocator());
            break;
        } else |err| {
            try testing.expectEqual(error.OutOfMemory, err);
        }
    }
}

test "summarizeFile and writeReport use the given dir" {
    const io = testing.io;
    var tmp = testing.tmpDir(.{});
    defer tmp.cleanup();
    try tmp.dir.writeFile(io, .{ .sub_path = "in.log", .data = "ERROR db: down\nWARN db: slow\nINFO web: hi\nbogus\n" });

    var s = try logstat.summarizeFile(testing.allocator, io, tmp.dir, "in.log");
    defer s.deinit(testing.allocator);
    try testing.expectEqual(@as(u32, 1), s.invalid);

    try logstat.writeReport(testing.allocator, io, tmp.dir, "in.log", "report.txt");
    const report = try tmp.dir.readFileAlloc(io, "report.txt", testing.allocator, .limited(4096));
    defer testing.allocator.free(report);
    try testing.expectEqualStrings("debug=0 info=1 warn=1 error=1 invalid=1\ndb 2\nweb 1\n", report);

    try testing.expectError(error.FileNotFound, logstat.summarizeFile(testing.allocator, io, tmp.dir, "nope.log"));
}

test "files over 1 MiB are rejected" {
    const io = testing.io;
    var tmp = testing.tmpDir(.{});
    defer tmp.cleanup();
    const big = try testing.allocator.alloc(u8, (1 << 20) + 100);
    defer testing.allocator.free(big);
    @memset(big, '\n');
    try tmp.dir.writeFile(io, .{ .sub_path = "big.log", .data = big });
    try testing.expectError(error.StreamTooLong, logstat.summarizeFile(testing.allocator, io, tmp.dir, "big.log"));
}
