//! Atom module consists of two types of atoms: Pure and Atom
//!
//! Pure atom contains metadata
//!
//! Atom contains children and PureAtom
const std = @import("std");

pub const AtomOptions = struct {
    access_count: i16 = 0,
    last_accessed: i64 = 0,
};

/// Pure Syvore Atom is the core data structure that stores data about the node in the Syvore Trie.
///
/// Path segment either stores the entire key or a part of the key.
///
/// Value is the data itself.
///
/// Access count is the number of times the node has been accessed.
///
/// Last accessed is the timestamp of the last time the node was accessed.
///
/// Created at is the timestamp of the node's creation.
///
pub const PureSyvoreAtom = struct {
    path: []const u8,
    value: ?[]const u8,
    access_count: i16,
    last_accessed: i64,
    created_at: i64,

    pub fn init(path: []const u8, value: ?[]const u8, options: ?AtomOptions) PureSyvoreAtom {
        const access_count = options.?.access_count;
        const now = std.time.timestamp();
        return PureSyvoreAtom{
            .path = path,
            .value = value,
            .access_count = access_count,
            .last_accessed = undefined,
            .created_at = now,
        };
    }

    pub fn deinit(self: *PureSyvoreAtom) void {
        self.path.deinit();
        self.value.deinit();
    }

    pub fn setValue(self: *PureSyvoreAtom, value: ?[]const u8) void {
        self.value = value.?;
    }

    pub fn updateAccessCount(self: *PureSyvoreAtom, access_count: ?i16) void {
        self.access_count = access_count orelse self.access_count +% 1;
        self.last_accessed = std.time.timestamp();
    }
};

pub const SyvoreAtom = struct {
    pure: PureSyvoreAtom,
    children: std.ArrayList(*SyvoreAtom),

    pub fn init(allocator: *std.mem.Allocator, key: []const u8, value: ?[]const u8) !SyvoreAtom {
        return SyvoreAtom{
            .pure = PureSyvoreAtom.init(key, value, null),
            .children = std.ArrayList(*SyvoreAtom).init(allocator.*),
        };
    }

    pub fn deinit(self: *SyvoreAtom, allocator: *std.mem.Allocator) void {
        for (self.children.items) |child| {
            child.deinit(allocator);
            allocator.destroy(child);
        }
        self.children.deinit();
    }

    pub fn addChild(self: *SyvoreAtom, allocator: *std.mem.Allocator, key: []const u8, value: ?[]const u8) !*SyvoreAtom {
        const child = try allocator.create(SyvoreAtom);
        child.* = try SyvoreAtom.init(allocator, key, value);
        try self.children.append(child);
        return child;
    }

    pub fn findChild(self: *const SyvoreAtom, key: []const u8) ?*SyvoreAtom {
        for (self.children.items) |child| {
            if (std.mem.eql(u8, child.pure.path, key)) {
                return child;
            }
        }
        return null;
    }
};
