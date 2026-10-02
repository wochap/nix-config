const std = @import("std");
const csvints = @import("csvints");

fn expectInts(line: []const u8, want: []const i64) !void {
    const got = try csvints.parseInts(std.testing.allocator, line);
    defer std.testing.allocator.free(got);
    try std.testing.expectEqualSlices(i64, want, got);
}

test "basic" {
    try expectInts("1,2,3", &.{ 1, 2, 3 });
}

test "spaces, tabs and signs" {
    try expectInts(" 10 ,\t-20,+30 ", &.{ 10, -20, 30 });
}

test "empty fields are skipped" {
    try expectInts(",,5,, ,6,", &.{ 5, 6 });
    try expectInts("", &.{});
    try expectInts(" , ", &.{});
}

test "i64 limits" {
    try expectInts("9223372036854775807,-9223372036854775808", &.{ std.math.maxInt(i64), std.math.minInt(i64) });
}

test "invalid numbers" {
    const a = std.testing.allocator;
    try std.testing.expectError(error.InvalidNumber, csvints.parseInts(a, "1,x,3"));
    try std.testing.expectError(error.InvalidNumber, csvints.parseInts(a, "1 2"));
    try std.testing.expectError(error.InvalidNumber, csvints.parseInts(a, "1.5"));
    try std.testing.expectError(error.InvalidNumber, csvints.parseInts(a, "9223372036854775808"));
}

test "no leaks on error after many values" {
    const a = std.testing.allocator;
    try std.testing.expectError(error.InvalidNumber, csvints.parseInts(a, "1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,bad"));
}
