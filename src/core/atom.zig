//! Syvore Atom is the data structure that is used to store the data in the Syvore Trie.
//! It has a path segment and potentially a value and children.

const std = @import("std");

pub const AtomOptions = struct {
    access_count: i16 = 0,
    last_accessed: i64 = 0,
};

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
};

pub const SyvoreAtom = struct {
    pure: PureSyvoreAtom,
    children: std.ArrayList(SyvoreAtom),

    pub fn init(allocator: std.mem.Allocator, path: []const u8, value: ?[]const u8) SyvoreAtom {
        return SyvoreAtom{
            .pure = PureSyvoreAtom.init(path, value),
            .children = std.ArrayList(SyvoreAtom).init(allocator),
        };
    }

    pub fn deinit(self: *SyvoreAtom) void {
        for (self.children.items) |child| {
            child.deinit();
        }
        self.children.deinit();
    }

    pub fn getOrCreate(self: *SyvoreAtom, path: std.mem.SplitIterator(u8, .sequence), value: []const u8) *SyvoreAtom {
        if (self.findChild(path)) |child| {
            child.access_count = child.access_count +% 1;
            child.last_accessed = std.time.timestamp();
            return child;
        }
        const new_atom = SyvoreAtom.init(self.allocator, path.rest().?, value);
        self.children.append(new_atom);
        return &new_atom;
    }

    pub fn findChild(self: *SyvoreAtom, path: std.mem.SplitIterator(u8, .sequence)) ?*SyvoreAtom {
        const segment = path.next().?;
        for (self.children.items) |child| {
            if (std.mem.eql(u8, child.path, segment)) {
                return &child;
            }
        }
    }
};
