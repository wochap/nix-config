const std = @import("std");

pub const Level = enum { debug, info, warn, err };

pub const SourceCount = struct {
    name: []const u8,
    count: u32,
};

pub const Summary = struct {
    /// Count per level, indexed by `@intFromEnum(Level)`.
    levels: [4]u32 = .{ 0, 0, 0, 0 },
    invalid: u32 = 0,
    /// Owned by the summary. Sorted by count (descending), then name (ascending).
    sources: []SourceCount = &.{},

    pub fn deinit(self: *Summary, gpa: std.mem.Allocator) void {
        for (self.sources) |s| gpa.free(s.name);
        gpa.free(self.sources);
        self.* = undefined;
    }

    pub fn format(self: Summary, w: *std.Io.Writer) std.Io.Writer.Error!void {
        try w.print("debug={d} info={d} warn={d} error={d} invalid={d}\n", .{
            self.levels[0], self.levels[1], self.levels[2], self.levels[3], self.invalid,
        });
        for (self.sources) |s| try w.print("{s} {d}\n", .{ s.name, s.count });
    }
};

const level_names = [_][]const u8{ "DEBUG", "INFO", "WARN", "ERROR" };

fn parseLevel(word: []const u8) ?Level {
    for (level_names, 0..) |name, i| {
        if (std.mem.eql(u8, word, name)) return @enumFromInt(i);
    }
    return null;
}

fn byCountThenName(_: void, a: SourceCount, b: SourceCount) bool {
    if (a.count != b.count) return a.count > b.count;
    return std.mem.lessThan(u8, a.name, b.name);
}

pub fn parse(gpa: std.mem.Allocator, text: []const u8) !Summary {
    var summary: Summary = .{};
    var list: std.ArrayList(SourceCount) = .empty;
    errdefer {
        for (list.items) |s| gpa.free(s.name);
        list.deinit(gpa);
    }
    var lines = std.mem.splitScalar(u8, text, '\n');
    while (lines.next()) |raw| {
        const line = std.mem.trim(u8, raw, " \t\r");
        if (line.len == 0) continue;
        const sp = std.mem.findScalar(u8, line, ' ') orelse {
            summary.invalid += 1;
            continue;
        };
        const colon = std.mem.findScalar(u8, line, ':') orelse {
            summary.invalid += 1;
            continue;
        };
        const level = parseLevel(line[0..sp]);
        const source = if (colon > sp) std.mem.trim(u8, line[sp + 1 .. colon], " ") else "";
        if (level == null or source.len == 0 or std.mem.findAny(u8, source, " \t") != null) {
            summary.invalid += 1;
            continue;
        }
        summary.levels[@intFromEnum(level.?)] += 1;
        for (list.items) |*s| {
            if (std.mem.eql(u8, s.name, source)) {
                s.count += 1;
                break;
            }
        } else {
            const name = try gpa.dupe(u8, source);
            errdefer gpa.free(name);
            try list.append(gpa, .{ .name = name, .count = 1 });
        }
    }
    std.mem.sort(SourceCount, list.items, {}, byCountThenName);
    summary.sources = try list.toOwnedSlice(gpa);
    return summary;
}

pub fn summarizeFile(gpa: std.mem.Allocator, io: std.Io, dir: std.Io.Dir, sub_path: []const u8) !Summary {
    const data = try dir.readFileAlloc(io, sub_path, gpa, .limited(1 << 20));
    defer gpa.free(data);
    return parse(gpa, data);
}

pub fn writeReport(gpa: std.mem.Allocator, io: std.Io, dir: std.Io.Dir, in_path: []const u8, out_path: []const u8) !void {
    var summary = try summarizeFile(gpa, io, dir, in_path);
    defer summary.deinit(gpa);
    const file = try dir.createFile(io, out_path, .{});
    defer file.close(io);
    var buf: [4096]u8 = undefined;
    var fw = file.writer(io, &buf);
    try fw.interface.print("{f}", .{summary});
    try fw.interface.flush();
}
