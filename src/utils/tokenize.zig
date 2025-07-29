//! Tokenize is a module that is used to tokenize the input string.

const std = @import("std");

pub fn Tokenize(input: []const u8, delimiter: ?[]const u8) std.mem.TokenIterator(u8, .sequence) {
    const d = delimiter orelse "*";
    const tokens = std.mem.tokenizeSequence(u8, input, d);
    return tokens;
}
