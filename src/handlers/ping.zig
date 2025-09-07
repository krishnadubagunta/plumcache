//! This module implements the handler for the PING command.
//! It is used to test the connection to the PlumCache server.

const std = @import("std");

/// `Ping` handles the PING command.
/// It returns a simple "PONG" string to indicate that the server is responsive.
///
/// Returns:
///   - A slice of `u8` containing the string "PONG".
pub fn Ping() []const u8 {
    return "PONG";
}
