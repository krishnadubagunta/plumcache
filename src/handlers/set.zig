//! This module implements the handler for the SET command.
//!
//! The SET command stores a key-value pair in the PlumStore. It tokenizes the
//! arguments to extract the key and value, then delegates to the PlumStore's
//! set method for actual storage.

const std = @import("std");
const plum = @import("../core/plum.zig");
const tokenize = @import("../utils/tokenize.zig");

/// `Set` handles the SET command by storing a key-value pair in the PlumStore.
///
/// It parses the arguments string to extract the key and value, then calls
/// the PlumStore's set method to perform the actual storage operation.
///
/// Parameters:
///   - `args`: A string containing the key and value separated by a space.
///
/// Returns:
///   - A slice of `u8` containing "OK" on success.
///
/// Errors:
///   - Can return errors from `plumStore.set` if the storage operation fails.
pub fn Set(args: []const u8) ![]const u8 {
    var tokens: std.mem.TokenIterator(u8, .sequence) = tokenize.Tokenize(args, " ");

    var plumStore = plum.GetPlumStore();
    plumStore.set(tokens.next().?, tokens.next().?) catch |err| switch (err) {
        error.OutOfMemory => {
            tokens.reset();
            std.debug.print("Out of memory, Key: {s}, Value: {s}", .{
                .Key = tokens.next().?,
                .Value = tokens.next().?,
            });
            return "ERROR";
        },
    };
    return "OK";
}
