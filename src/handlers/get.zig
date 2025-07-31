//! Handler for the SET command.

const std = @import("std");
const syvore = @import("../core/syvore.zig");
const tokenize = @import("../utils/tokenize.zig");

pub fn Get(args: []const u8) []const u8 {
    var tokens: std.mem.TokenIterator(u8, .sequence) = tokenize.Tokenize(args, " ");
    const key: []const u8 = tokens.next().?;

    var syStore = syvore.GetSyvoreStore();
    const value = syStore.get(key);
    std.debug.print("Value: {?s}\n", .{value});
    return value orelse "NOT_FOUND";
}
