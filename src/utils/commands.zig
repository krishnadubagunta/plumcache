//! This module is responsible for parsing, defining, and executing the commands
//! supported by PlumCache. It acts as a bridge between the raw command strings
//! received from the client and the corresponding handler functions that implement
//! the command logic.

const std = @import("std");
const handlers = @import("../handlers/handler.zig");

/// `Command` is an enumeration of all the commands supported by PlumCache.
/// This allows for type-safe handling of commands throughout the system.
pub const Command = enum {
    PING,
    SET,
    GET,
    DELETE,
};

/// `ParseCommand` converts a raw command string into a `Command` enum variant.
///
/// It performs a case-sensitive comparison of the input string against the known commands.
///
/// Parameters:
///   - `cmd`: The command string to parse (e.g., "PING", "SET").
///
/// Returns:
///   - An optional `Command`. Returns the corresponding enum variant if the command is recognized,
///     otherwise returns `null`.
pub fn ParseCommand(cmd: []const u8) ?Command {
    std.debug.print("Parsing command: {s}\n", .{cmd});
    if (std.mem.eql(u8, cmd, "PING")) return Command.PING;
    if (std.mem.eql(u8, cmd, "SET")) return Command.SET;
    if (std.mem.eql(u8, cmd, "GET")) return Command.GET;
    if (std.mem.eql(u8, cmd, "DELETE")) return Command.DELETE;
    return null;
}

/// `ExecuteCommand` dispatches a parsed command to its corresponding handler function.
///
/// It takes a `Command` variant and its arguments, and invokes the appropriate logic
/// from the `handlers` module.
///
/// Parameters:
///   - `cmd`: The `Command` enum variant to execute.
///   - `args`: A slice containing the arguments for the command.
///
/// Returns:
///   - A slice of `u8` representing the response to be sent back to the client.
///     Returns "ERROR" if the command handler encounters an error or is not implemented.
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
