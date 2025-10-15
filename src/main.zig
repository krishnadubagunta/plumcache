//! This module contains the `main` function, the entry point of the PlumCache server application.
//!
//! The `main` function is responsible for:
//! 1. Initializing the necessary components of PlumCache, such as the orchestrator and the store.
//! 2. Setting up and starting the TCP server to listen for incoming client connections.
//! 3. Continuously accepting new client connections and delegating their handling to the `server.handleConnection` function.
//!
//! This file adheres to the Zig convention where `main.zig` hosts the primary executable logic.
const std = @import("std");
const lib = @import("plum_lib");
const server = @import("server.zig");

pub fn createOrchestrator(allocator: std.mem.Allocator) !lib.orchestration.Orchestrator {
    return lib.orchestration.Orchestrator.init(allocator);
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const address = try std.net.Address.parseIp("127.0.0.1", 8080);
    var orchestrator = try createOrchestrator(allocator);
    try orchestrator.loadPlugins();
    try lib.store.InitPlumStore(allocator);

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
