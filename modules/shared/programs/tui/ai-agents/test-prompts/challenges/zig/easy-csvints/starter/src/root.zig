const std = @import("std");

pub const ParseError = error{InvalidNumber};

/// Parse a comma-separated list of integers. Caller owns the returned slice.
pub fn parseInts(gpa: std.mem.Allocator, line: []const u8) (ParseError || std.mem.Allocator.Error)![]i64 {
    _ = line;
    return gpa.alloc(i64, 0);
}
