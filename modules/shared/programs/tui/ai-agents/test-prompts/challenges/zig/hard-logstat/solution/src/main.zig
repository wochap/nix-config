const std = @import("std");
const logstat = @import("logstat");

pub fn main(init: std.process.Init) !u8 {
    const io = init.io;
    const args = try init.minimal.args.toSlice(init.arena.allocator());

    var ebuf: [256]u8 = undefined;
    var ew: std.Io.File.Writer = .init(.stderr(), io, &ebuf);
    const stderr = &ew.interface;

    if (args.len != 2) {
        try stderr.print("usage: logstat <file>\n", .{});
        try stderr.flush();
        return 2;
    }

    var summary = logstat.summarizeFile(init.gpa, io, std.Io.Dir.cwd(), args[1]) catch |e| {
        try stderr.print("error: {t}\n", .{e});
        try stderr.flush();
        return 1;
    };
    defer summary.deinit(init.gpa);

    var obuf: [4096]u8 = undefined;
    var ow: std.Io.File.Writer = .init(.stdout(), io, &obuf);
    try ow.interface.print("{f}", .{summary});
    try ow.interface.flush();
    return 0;
}
