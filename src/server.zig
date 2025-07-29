//! Server module handles all the incoming connections and handles the commands.
const std = @import("std");
const lib = @import("syvore_lib");

pub fn handleConnection(conn: std.net.Stream) !void {
    defer conn.close();

    var buf: [1024]u8 = undefined;
    const bytes_read = try conn.read(&buf);
    const line = std.mem.trimRight(u8, buf[0..bytes_read], "\r\n");

    var tokens: std.mem.SplitIterator(u8, .sequence) = lib.tokenize.Tokenize(line, null);
    if (tokens.next()) |cmd| {
        const command = lib.commands.ParseCommand(cmd) orelse {
            std.debug.print("Invalid command: {s}\n", .{cmd});
            return;
        };
        const response = lib.commands.ExecuteCommand(command, tokens.rest());
        try conn.writeAll(response);
    }
}
