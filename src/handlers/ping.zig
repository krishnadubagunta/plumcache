//! Handler for the PING command.

const std = @import("std");

pub fn Ping() []const u8 {
    return "PONG";
}
