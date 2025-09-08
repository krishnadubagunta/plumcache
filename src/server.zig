//! This module implements the networking server for PlumCache.
//!
//! It handles TCP connections, parses incoming commands from clients,
//! and routes them to the appropriate command handlers. The server acts as
//! the interface between network clients and the core database functionality.
//!
//! The server follows a simple text-based protocol where:
//! 1. Commands are received as text strings over TCP
//! 2. Each command is parsed and validated
//! 3. Commands are executed by the relevant handlers
//! 4. Responses are sent back to the client
const std = @import("std");
const lib = @import("plum_lib");

/// Handles a single client connection by processing commands and sending responses.
///
/// This function:
/// 1. Reads data from the connection
/// 2. Parses the command string
/// 3. Validates and executes the command
/// 4. Returns the response to the client
///
/// The connection is automatically closed when this function returns,
/// regardless of whether it completes successfully or errors out.
///
/// Parameters:
///   - `conn`: The network stream representing the client connection.
///
/// Errors:
///   - Can return I/O errors from reading or writing to the connection.
pub fn handleConnection(conn: std.net.Stream) !void {
    defer conn.close();

    // Buffer to store incoming command data
    var buf: [1024]u8 = undefined;
    // Read from connection and trim trailing newlines
    const bytes_read = try conn.read(&buf);
    const line = std.mem.trimRight(u8, buf[0..bytes_read], "\r\n");
    std.debug.print("Line: {s}\n", .{line});
    // Tokenize the input line using space as delimiter
    var tokens: std.mem.TokenIterator(u8, .sequence) = lib.tokenize.Tokenize(line, " ");

    // Extract the command (first token) and process it
    if (tokens.next()) |cmd| {
        // Parse the command string into a Command enum, handling invalid commands
        const command = lib.commands.ParseCommand(cmd) orelse {
            std.debug.print("Invalid command: {s}\n", .{cmd});
            return;
        };
        // Execute the command with the remaining tokens as arguments
        const response = lib.commands.ExecuteCommand(command, tokens.rest());
        std.debug.print("Response: {s}\n", .{response});
        // Send the response back to the client
        try conn.writeAll(response);
    }
}
