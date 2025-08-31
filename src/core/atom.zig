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
pub const PurePlumAtom = struct {
    path: []const u8,
    value: ?[]const u8,
    access_count: i16,
    last_accessed: i64,
    created_at: i64,

    pub fn init(path: []const u8, value: ?[]const u8, options: ?AtomOptions) PurePlumAtom {
        var access_count: i16 = 0;
        var last_accessed: i64 = 0;
        if (options) |opt| {
            access_count = opt.access_count;
            last_accessed = opt.last_accessed;
        }
        const now = std.time.timestamp();
        return PurePlumAtom{
            .path = path,
            .value = value,
            .access_count = access_count,
            .last_accessed = last_accessed,
            .created_at = now,
        };
    }

    pub fn deinit(self: *PurePlumAtom) void {
        self.path.deinit();
        self.value.deinit();
    }

    pub fn setValue(self: *PurePlumAtom, value: ?[]const u8) void {
        self.value = value.?;
    }

    pub fn updateAccessCount(self: *PurePlumAtom, access_count: ?i16) void {
        if (access_count) |ac| {
            self.access_count = ac;
        } else {
            self.access_count = self.access_count +% 1;
        }
        self.last_accessed = std.time.timestamp();
    }
};

pub const PlumAtom = struct {
    pure: PurePlumAtom,
    children: std.ArrayList(*PlumAtom),

    pub fn init(allocator: std.mem.Allocator, key: []const u8, value: ?[]const u8) !PlumAtom {
        return PlumAtom{
            .pure = PurePlumAtom.init(key, value, null),
            .children = std.ArrayList(*PlumAtom).init(allocator),
        };
    }

    pub fn deinit(self: *PlumAtom, allocator: std.mem.Allocator) void {
        for (self.children.items) |child| {
            child.deinit(allocator);
            allocator.destroy(child);
        }
        self.children.deinit();
    }

    pub fn addChild(self: *PlumAtom, allocator: std.mem.Allocator, key: []const u8, value: ?[]const u8) !*PlumAtom {
        const child = try allocator.create(PlumAtom);
        child.* = try PlumAtom.init(allocator, key, value);
        try self.children.append(child);
        return child;
    }

    pub fn findChild(self: *const PlumAtom, key: []const u8) ?*PlumAtom {
        for (self.children.items) |child| {
            if (std.mem.eql(u8, child.pure.path, key)) {
                return child;
            }
        }
        return null;
    }
};
