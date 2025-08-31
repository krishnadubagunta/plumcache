//! Handler for the SET command.

const std = @import("std");
const plum = @import("../core/plum.zig");
const tokenize = @import("../utils/tokenize.zig");

pub fn Get(args: []const u8) []const u8 {
    var tokens: std.mem.TokenIterator(u8, .sequence) = tokenize.Tokenize(args, " ");
    const key: []const u8 = tokens.next().?;

    var plumStore = plum.GetPlumStore();
    const value = plumStore.get(key);
    std.debug.print("Value: {?s}\n", .{value});
    return value orelse "NOT_FOUND";
}
