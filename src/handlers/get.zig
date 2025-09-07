//! This module implements the handler for the GET command.
//!
//! The GET command retrieves the value associated with a key from the PlumStore.
//! It tokenizes the arguments to extract the key, then delegates to the PlumStore's
//! get method for the actual retrieval operation.

const std = @import("std");
const plum = @import("../core/plum.zig");
const tokenize = @import("../utils/tokenize.zig");

/// `Get` handles the GET command by retrieving a value from the PlumStore.
///
/// It parses the arguments string to extract the key, then calls the PlumStore's
/// get method to perform the actual retrieval operation.
///
/// Parameters:
///   - `args`: A string containing the key to retrieve.
///
/// Returns:
///   - A slice of `u8` containing the value if found, or "NOT_FOUND" if the key doesn't exist.
pub fn Get(args: []const u8) []const u8 {
    var tokens: std.mem.TokenIterator(u8, .sequence) = tokenize.Tokenize(args, " ");
    const key: []const u8 = tokens.next().?;

    var plumStore = plum.GetPlumStore();
    const value = plumStore.get(key);
    return value orelse "NOT_FOUND";
}
