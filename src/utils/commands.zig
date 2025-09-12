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
    // Log the command string being parsed for debugging purposes.
    std.debug.print("Parsing command: {s}\n", .{cmd});
    // Compare the input command string with known command variants.
    if (std.mem.eql(u8, cmd, "PING")) return Command.PING;
    if (std.mem.eql(u8, cmd, "SET")) return Command.SET;
    if (std.mem.eql(u8, cmd, "GET")) return Command.GET;
    if (std.mem.eql(u8, cmd, "DELETE")) return Command.DELETE;
    // If no matching command is found, return null to indicate it's an unrecognized command.
    return null;
}

/// `ExecuteCommand` dispatches a parsed command to its corresponding handler function.
///
/// It takes a `Command` variant and its arguments, and invokes the appropriate logic
/// from the `handlers` module.
///
/// Parameters:
///   - `cmd`: The `Command` enum variant to execute.
/// `ExecuteCommand` dispatches a parsed command to its corresponding handler function.
///
/// This function takes a recognized `Command` enum variant and its associated arguments,
/// then invokes the appropriate command-specific logic from the `handlers` module.
/// It acts as the central router for all client commands.
///
/// Parameters:
///   - `cmd`: The `Command` enum variant representing the client's request (e.g., `Command.PING`).
///            This is obtained from `ParseCommand`.
///   - `args`: A slice of `u8` containing the raw arguments for the command. This string is passed
///             directly to the specific handler function for further parsing if required.
///
/// Returns:
///   - A slice of `u8` representing the response string to be sent back to the client.
///     For commands that succeed, this will typically be "OK", a retrieved value, or "PONG".
///     Returns "ERROR" if the command handler encounters an error (e.g., `error.OutOfMemory`)
///     or if the command is recognized but its functionality is not yet implemented.
pub fn ExecuteCommand(cmd: Command, args: []const u8) []const u8 {
    // Log the command being executed and its arguments for debugging purposes.
    std.debug.print("Executing command: {any}, with args: \"{s}\"\n", .{ cmd, args });
    // Use a switch statement to dispatch the command to the appropriate handler function
    // based on the `Command` enum variant.
    switch (cmd) {
        // Handle the PING command: call the `ping.Ping` handler, which returns "PONG".
        Command.PING => return handlers.ping.Ping(),
        // Handle the SET command: call the `set.Set` handler with the provided arguments.
        // Catch any potential errors (like OutOfMemory) and return "ERROR".
        Command.SET => return handlers.set.Set(args) catch return "ERROR",
        // Handle the GET command: call the `get.Get` handler with the provided arguments.
        Command.GET => return handlers.get.Get(args),
        // Handle the DELETE command: currently marked as not implemented.
        Command.DELETE => {
            // Log a message indicating that the DELETE command is not yet implemented.
            std.debug.print("DELETE command not implemented yet.\n", .{});
            // Return an "ERROR" response to the client.
            return "ERROR";
        },
    }
}
