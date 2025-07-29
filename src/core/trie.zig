const std = @import("std");
const atom = @import("atom.zig");
const tokenize = @import("../utils/tokenize.zig");

pub const SyvoreTrie = struct {
    root: atom.SyvoreAtom,
    allocator: *std.mem.Allocator,

    pub fn init(allocator: *std.mem.Allocator) !SyvoreTrie {
        return SyvoreTrie{
            .allocator = allocator,
            .root = try atom.SyvoreAtom.init(allocator, "", null),
        };
    }

    pub fn deinit(self: *SyvoreTrie) void {
        self.root.deinit(self.allocator);
    }

    pub fn set(self: *SyvoreTrie, full_key: []const u8, value: []const u8) !void {
        var tokens = tokenize.Tokenize(full_key, null);
        var current: *atom.SyvoreAtom = &self.root;

        while (tokens.next()) |segment| {
            const maybe_child = current.findChild(segment);

            if (maybe_child) |child| {
                current = child;
            } else {
                current = try current.addChild(self.allocator, segment, null);
            }
        }

        current.pure.setValue(value);
    }

    pub fn get(self: *SyvoreTrie, full_key: []const u8) ?[]const u8 {
        var tokens = std.mem.split(u8, full_key, ":");
        var current: *atom.SyvoreAtom = &self.root;

        while (tokens.next()) |segment| {
            const child = current.findChild(segment) orelse return null;
            current = child;
        }

        current.pure.updateAccess();
        return current.pure.value;
    }
};
