//! Commands is a module that is used to parse and defined the commands for the SyvoreDB.

const std = @import("std");
const handlers = @import("../handlers/handler.zig");

pub const Command = enum {
    PING,
    SET,
    GET,
    DELETE,
};

pub fn ParseCommand(cmd: []const u8) ?Command {
    std.debug.print("Parsing command: {s}\n", .{cmd});
    if (std.mem.eql(u8, cmd, "PING")) return Command.PING;
    if (std.mem.eql(u8, cmd, "SET")) return Command.SET;
    if (std.mem.eql(u8, cmd, "GET")) return Command.GET;
    if (std.mem.eql(u8, cmd, "DELETE")) return Command.DELETE;
    return null;
}

pub fn ExecuteCommand(cmd: Command, args: []const u8) []const u8 {
    std.debug.print("Executing command: {}\n", .{cmd});
    switch (cmd) {
        Command.PING => return handlers.ping.Ping(),
        Command.SET => return handlers.set.Set(args) catch return "ERROR",
        Command.GET => return handlers.get.Get(args),
        Command.DELETE => {
            std.debug.print("GET or DELETE not implemented\n", .{});
            return "ERROR";
        },
    }
}
