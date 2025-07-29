//! Tokenize is a module that is used to tokenize the input string.

const std = @import("std");

pub fn Tokenize(input: []const u8, delimiter: ?[]const u8) std.mem.SplitIterator(u8, .sequence) {
    const d = delimiter orelse "*";
    const tokens = std.mem.splitSequence(u8, input, d);
    return tokens;
}
