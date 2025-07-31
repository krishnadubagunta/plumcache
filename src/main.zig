//! By convention, main.zig is where your main function lives in the case that
//! you are building an executable. If you are making a library, the convention
//! is to delete this file and start with root.zig instead.
const std = @import("std");
const lib = @import("syvore_lib");
const server = @import("server.zig");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const address = try std.net.Address.parseIp("127.0.0.1", 8080);
    try lib.syvore.InitSyvoreStore(allocator);

    var listener = try address.listen(.{
        .reuse_address = true,
    });

    std.debug.print("Listening on 127.0.0.1:8080\n", .{});

    while (true) {
        const conn = listener.accept() catch |err| {
            std.debug.print("Error accepting connection: {}\n", .{err});
            continue;
        };
        try server.handleConnection(conn.stream);
    }
}
