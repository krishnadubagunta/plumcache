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
/// 1. Reads data from the client connection.
/// 2. Parses the received command string.
/// 3. Validates and executes the parsed command using the PlumCache command system.
/// 4. Sends the generated response back to the client.
///
/// The connection is automatically closed when this function returns,
/// regardless of whether it completes successfully or errors out, thanks to `defer conn.close()`.
///
/// Parameters:
///   - `conn`: The network stream representing the client connection. This stream is used
///             for both reading incoming requests and writing outgoing responses.
///
/// Errors:
///   - Can return I/O errors (`error.Io`) from `conn.read` or `conn.writeAll` if there
///     are issues with network communication.
///   - Can return other errors propagated from `lib.commands.ExecuteCommand` if a
///     command handler encounters a problem (e.g., `error.OutOfMemory`).
pub fn handleConnection(conn: std.net.Stream) !void {
    // Ensure the connection is closed when the function exits, regardless of success or failure.
    defer conn.close();

    // Declare a fixed-size buffer to store incoming command data from the client.
    var buf: [1024]u8 = undefined;
    // Read data from the client stream into the buffer. `bytes_read` indicates how many bytes were actually read.
    const bytes_read = try conn.read(&buf);
    // Trim any trailing carriage returns and newlines from the received data to get the clean command line.
    const line = std.mem.trimRight(u8, buf[0..bytes_read], "\r\n");
    // Print the received command line for debugging purposes.
    std.debug.print("Line: {s}\n", .{line});
    // Create a token iterator to split the command line into individual tokens (command and arguments)
    // using a space as the delimiter.
    var tokens: std.mem.TokenIterator(u8, .sequence) = lib.tokenize.Tokenize(line, " ");

    // Attempt to extract the first token, which is expected to be the command itself.
    if (tokens.next()) |cmd| {
        // Parse the extracted command string into a `Command` enum variant.
        // If the command is not recognized, `ParseCommand` returns `null`.
        const command = lib.commands.ParseCommand(cmd) orelse {
            // Log an error if the command is invalid and return, closing the connection.
            std.debug.print("Invalid command: {s}\n", .{cmd});
            return;
        };
        // Execute the parsed command, passing the remaining tokens as arguments.
        // The `ExecuteCommand` function handles dispatching to the appropriate handler and returns a response.
        const response = lib.commands.ExecuteCommand(command, tokens.rest());
        // Print the generated response for debugging.
        std.debug.print("Response: {s}\n", .{response});
        // Write the response back to the client over the network stream.
        try conn.writeAll(response);
    }
}
