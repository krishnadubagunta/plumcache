//! Syvore Trie is the data structure that is used to store the segments of the key with
//! potentially every node on each level could hold a value.
//! Syvore Trie is created from the segment of the key with a : delimiter.
//! Each Syvore Trie node is called SyvoreAtom.

const std = @import("std");
const atom = @import("atom.zig");

pub const SyvoreTrie = struct {
    root: atom.SyvoreAtom,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) SyvoreTrie {
        return SyvoreTrie{
            .root = atom.SyvoreAtom.init(allocator, "", null),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *SyvoreTrie) void {
        self.root.deinit();
    }
};
