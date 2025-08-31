//! Handler for the SET command.

const std = @import("std");
const plum = @import("../core/plum.zig");
const tokenize = @import("../utils/tokenize.zig");
const allocator = std.heap.page_allocator;

/// Set function copies the values of key and value to the heap
/// and then passes them to the plum store.
///
/// This is done to avoid resetting the values when their memory is freed
///
pub fn Set(args: []const u8) ![]const u8 {
    var tokens: std.mem.TokenIterator(u8, .sequence) = tokenize.Tokenize(args, " ");
    const key_copy = try allocator.dupe(u8, tokens.next().?);
    const val_copy = try allocator.dupe(u8, tokens.next().?);
    defer allocator.free(key_copy);
    defer allocator.free(val_copy);

    var plumStore = plum.GetPlumStore();
    try plumStore.set(key_copy, val_copy);
    return "OK";
}
