const std = @import("std");
const atom = @import("atom.zig");
const tokenize = @import("../utils/tokenize.zig");

pub const PlumTrie = struct {
    root: atom.PlumAtom,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) !PlumTrie {
        return PlumTrie{
            .allocator = allocator,
            .root = try atom.PlumAtom.init(allocator, "", null),
        };
    }

    pub fn deinit(self: *PlumTrie) void {
        self.root.deinit(self.allocator);
    }

    pub fn set(self: *PlumTrie, full_key: []const u8, value: []const u8) !void {
        const key_copy = try self.allocator.dupe(u8, full_key);
        const value_copy = try self.allocator.dupe(u8, value);
        var tokens = tokenize.Tokenize(key_copy, null);
        var current: *atom.PlumAtom = &self.root;

        while (tokens.next()) |segment| {
            const maybe_child = current.findChild(segment);

            if (maybe_child) |child| {
                current = child;
            } else {
                current = try current.addChild(self.allocator, segment, null);
            }
        }

        current.pure.setValue(value_copy);
    }

    pub fn get(self: *PlumTrie, full_key: []const u8) ?[]const u8 {
        var tokens = tokenize.Tokenize(full_key, null);
        var current: *atom.PlumAtom = &self.root;

        while (tokens.next()) |segment| {
            const child = current.findChild(segment) orelse return null;
            current = child;
        }

        current.pure.updateAccessCount(null);
        return current.pure.value;
    }
};
