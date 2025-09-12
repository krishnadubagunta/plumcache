//! This module implements the handler for the GET command.
//!
//! The GET command retrieves the value associated with a key from the PlumStore.
//! It tokenizes the arguments to extract the key, then delegates to the PlumStore's
//! get method for the actual retrieval operation.

const std = @import("std");
const plum = @import("../core/store.zig");
const tokenize = @import("../utils/tokenize.zig");

/// `Get` handles the GET command by retrieving a value from the PlumStore.
///
/// It parses the arguments string to extract the key, then calls the PlumStore's
/// get method to perform the actual retrieval operation.
///
/// Parameters:
///   - `args`: A string containing the key to retrieve. This string is expected
///             to be the full key, potentially including trie path segments.
///
/// Returns:
///   - A slice of `u8` containing the retrieved value if the key is found.
///   - Returns the string "NOT_FOUND" if the key does not exist in the PlumStore.
pub fn Get(args: []const u8) []const u8 {
    // Create a token iterator to parse the `args` string.
    // The delimiter is a space, expecting a format like "GET <key>".
    var tokens: std.mem.TokenIterator(u8, .sequence) = tokenize.Tokenize(args, " ");

    // Obtain the singleton instance of the PlumStore.
    // It's assumed that `InitPlumStore` has already been called.
    var plumStore = plum.GetPlumStore();
    // Attempt to retrieve the value associated with the first token (the key).
    // The `tokens.next().?` unwraps the optional, assuming a key is always present.
    return plumStore.get(tokens.next().?) catch |err| {
        // Handle potential errors from `plumStore.get`.
        return switch (err) {
            // If the key is not found, return the "NOT_FOUND" string.
            error.KeyNotFound => "NOT_FOUND",
            // For any other unexpected errors, a generic "ERROR" could be returned,
            // or more specific error handling could be implemented.
        };
    };
}
