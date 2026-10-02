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
        _ = self;
        _ = gpa;
    }

    pub fn format(self: Summary, w: *std.Io.Writer) std.Io.Writer.Error!void {
        _ = self;
        _ = w;
    }
};

pub fn parse(gpa: std.mem.Allocator, text: []const u8) !Summary {
    _ = gpa;
    _ = text;
    return error.NotImplemented;
}

pub fn summarizeFile(gpa: std.mem.Allocator, io: std.Io, dir: std.Io.Dir, sub_path: []const u8) !Summary {
    _ = gpa;
    _ = io;
    _ = dir;
    _ = sub_path;
    return error.NotImplemented;
}

pub fn writeReport(gpa: std.mem.Allocator, io: std.Io, dir: std.Io.Dir, in_path: []const u8, out_path: []const u8) !void {
    _ = gpa;
    _ = io;
    _ = dir;
    _ = in_path;
    _ = out_path;
    return error.NotImplemented;
}
