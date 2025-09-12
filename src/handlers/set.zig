//! This module implements the handler for the SET command.
//!
//! The SET command stores a key-value pair in the PlumStore. It tokenizes the
//! arguments to extract the key and value, then delegates to the PlumStore's
//! set method for actual storage.

const std = @import("std");
const plum = @import("../core/store.zig");
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
    // Create a token iterator to parse the `args` string, using a space as the delimiter.
    // This is expected to extract the key and the value from the input string.
    var tokens: std.mem.TokenIterator(u8, .sequence) = tokenize.Tokenize(args, " ");

    // Obtain the singleton instance of PlumStore.
    // It's assumed that `InitPlumStore` has already been called.
    var plumStore = plum.GetPlumStore();
    // Attempt to set the key-value pair in the PlumStore.
    // `tokens.next().?` is used twice to extract both the key and the value.
    plumStore.set(tokens.next().?, tokens.next().?) catch |err| switch (err) {
        // Handle the specific `error.OutOfMemory` case.
        error.OutOfMemory => {
            // Reset the token iterator to re-parse the arguments for logging purposes.
            tokens.reset();
            // Print a debug message indicating out-of-memory error along with the key and value.
            std.debug.print("Out of memory, Key: {s}, Value: {s}", .{
                .Key = tokens.next().?,
                .Value = tokens.next().?,
            });
            // Return a generic "ERROR" string to the client.
            return "ERROR";
        },
    };
    // If the `set` operation is successful, return "OK".
    return "OK";
}
