const std = @import("std");

pub const ParseError = error{InvalidNumber};

/// Parse a comma-separated list of integers. Caller owns the returned slice.
pub fn parseInts(gpa: std.mem.Allocator, line: []const u8) (ParseError || std.mem.Allocator.Error)![]i64 {
    var list: std.ArrayList(i64) = .empty;
    errdefer list.deinit(gpa);
    var it = std.mem.splitScalar(u8, line, ',');
    while (it.next()) |raw| {
        const field = std.mem.trim(u8, raw, " \t");
        if (field.len == 0) continue;
        const n = std.fmt.parseInt(i64, field, 10) catch return error.InvalidNumber;
        try list.append(gpa, n);
    }
    return list.toOwnedSlice(gpa);
}
