//! Handler for the SET command.

const std = @import("std");
const syvore = @import("../core/syvore.zig");
const tokenize = @import("../utils/tokenize.zig");

pub fn Set(args: []const u8) []const u8 {
    var tokens: std.mem.SplitIterator(u8, .sequence) = tokenize.Tokenize(args, null);
    const key: []const u8 = tokens.next().?;
    const value: []const u8 = tokens.next().?;

    var syStore = syvore.SyvoreStore.init(std.heap.page_allocator);
    syStore.set(key, value) catch unreachable;
    return "OK";
}
