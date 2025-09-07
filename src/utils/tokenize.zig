//! This module provides string tokenization functionality for PlumCache.
//!
//! It offers a simplified interface over Zig's standard library tokenization,
//! allowing for consistent tokenization across the codebase while providing
//! sensible defaults for delimiters.

const std = @import("std");

/// Tokenizes an input string using the specified delimiter or a default one.
///
/// This function provides a simplified interface to Zig's `std.mem.tokenizeSequence`.
/// If no delimiter is provided, it defaults to "*", which is useful for many
/// PlumCache operations that use namespaced keys.
///
/// Parameters:
///   - `input`: The string to tokenize.
///   - `delimiter`: An optional delimiter string. If null, defaults to "*".
///
/// Returns:
///   - A token iterator that can be used to iterate through the tokens.
///
/// Example:
///   ```
///   var tokens = Tokenize("user:1001:name", ":");
///   const namespace = tokens.next(); // "user"
///   const id = tokens.next();        // "1001"
///   const field = tokens.next();     // "name"
///   ```
pub fn Tokenize(input: []const u8, delimiter: ?[]const u8) std.mem.TokenIterator(u8, .sequence) {
    const d = delimiter orelse "*";
    const tokens = std.mem.tokenizeSequence(u8, input, d);
    return tokens;
}
