//! This module defines the `PlumAtom` and `PurePlumAtom` structs, which are fundamental
//! data structures within PlumCache.
//!
//! `PurePlumAtom` represents a single, indivisible data entry, akin to a key-value pair,
//! but with additional metadata such as access timestamps and counters. It's the "pure"
//! data component.
//!
//! `PlumAtom` is a composite structure used in the `PlumTrie`. It contains a `PurePlumAtom`
//! for its own data and a hash map of children `PlumAtom`s, forming a node in the trie.
//! This allows for the hierarchical organization of data.
const std = @import("std");

/// `AtomOptions` provides optional parameters for initializing a `PurePlumAtom`.
/// This allows for setting initial values for metadata fields upon creation.
pub const AtomOptions = struct {
    /// The initial number of times the atom has been accessed. Defaults to 0.
    access_count: i16 = 0,
    /// The initial timestamp of the last access. Defaults to 0.
    last_accessed: i64 = 0,
};

/// `PurePlumAtom` is the core data structure for a single key-value entry in PlumCache.
/// It holds the value associated with a key, along with metadata for cache management
/// and analytics.
pub const PurePlumAtom = struct {
    /// The key for this atom. It can be a full key for a simple entry or a path segment in a trie.
    path: []const u8,
    /// The value stored in this atom. It's optional to allow for nodes that only serve as path intermediaries.
    value: ?[]const u8,
    /// The number of times this atom has been accessed. Useful for eviction policies like LFU.
    access_count: i16,
    /// The Unix timestamp of the last access. Useful for eviction policies like LRU.
    last_accessed: i64,
    /// The Unix timestamp of when the atom was created.
    created_at: i64,

    /// Initializes a new `PurePlumAtom`.
    ///
    /// It allocates memory for the `path` and sets initial metadata. `value` is initialized to `null`.
    ///
    /// Parameters:
    ///   - `allocator`: The memory allocator to use for duplicating the path.
    ///   - `path`: The key or path segment for this atom.
    ///   - `options`: Optional initial values for `access_count` and `last_accessed`.
    ///
    /// Returns:
    ///   - A new `PurePlumAtom` instance.
    ///
    /// Errors:
    ///   - Can return allocation errors from `allocator.dupe`.
    pub fn init(allocator: std.mem.Allocator, path: []const u8, options: ?AtomOptions) !PurePlumAtom {
        var access_count: i16 = 0;
        var last_accessed: i64 = 0;
        if (options) |opt| {
            access_count = opt.access_count;
            last_accessed = opt.last_accessed;
        }
        const now = std.time.timestamp();
        return PurePlumAtom{
            .path = try allocator.dupe(u8, path),
            .value = null,
            .access_count = access_count,
            .last_accessed = last_accessed,
            .created_at = now,
        };
    }

    /// Deinitializes the `PurePlumAtom`, freeing memory allocated for `path` and `value`.
    pub fn deinit(self: *PurePlumAtom) void {
        self.path.deinit();
        self.value.deinit();
    }

    /// Sets or updates the value of the atom.
    ///
    /// It allocates memory for the `value` and duplicates its content.
    ///
    /// Parameters:
    ///   - `allocator`: The memory allocator to use for duplicating the value.
    ///   - `value`: The value to be set.
    ///
    /// Errors:
    ///   - Can return allocation errors from `allocator.dupe`.
    pub fn setValue(self: *PurePlumAtom, allocator: std.mem.Allocator, value: []const u8) !void {
        self.value = try allocator.dupe(u8, value);
    }

    /// Updates the access metadata for the atom.
    ///
    /// It either sets the `access_count` to a specific value or increments it by one.
    /// It also updates `last_accessed` to the current timestamp.
    ///
    /// Parameters:
    ///   - `access_count`: An optional new value for the access count. If `null`, the count is incremented.
    pub fn updateAccessCount(self: *PurePlumAtom, access_count: ?i16) void {
        if (access_count) |ac| {
            self.access_count = ac;
        } else {
            self.access_count = self.access_count +% 1;
        }
        self.last_accessed = std.time.timestamp();
    }
};

/// `PlumAtom` represents a node within a `PlumTrie`.
///
/// It combines a `PurePlumAtom` to store its own data and a hash map of children
/// to form the branches of the trie. This structure allows for hierarchical key organization.
pub const PlumAtom = struct {
    /// The data and metadata for this node in the trie.
    pure: PurePlumAtom,
    /// A map of child path segments to their corresponding `PlumAtom` nodes.
    children: std.StringHashMap(*PlumAtom),

    /// Initializes a new `PlumAtom`.
    ///
    /// It creates a `PurePlumAtom` for the given key and initializes an empty children map.
    ///
    /// Parameters:
    ///   - `allocator`: The memory allocator for internal structures.
    ///   - `key`: The path segment for this atom.
    ///
    /// Returns:
    ///   - A new `PlumAtom` instance.
    ///
    /// Errors:
    ///   - Can return errors from `PurePlumAtom.init`.
    pub fn init(allocator: std.mem.Allocator, key: []const u8) !PlumAtom {
        const children = std.StringHashMap(*PlumAtom).init(allocator);

        return PlumAtom{
            .pure = try PurePlumAtom.init(allocator, key, null),
            .children = children,
        };
    }

    /// Deinitializes the `PlumAtom` and all its descendants recursively.
    ///
    /// It iterates through all children, deinitializes and destroys them, and then
    /// deinitializes its own children map.
    ///
    /// Parameters:
    ///   - `allocator`: The memory allocator used to destroy child atoms.
    pub fn deinit(self: *PlumAtom, allocator: std.mem.Allocator) void {
        for (self.children.items()) |child| {
            child.value.deinit(allocator);
            allocator.destroy(child.value);
        }
        self.children.deinit();
    }

    /// Adds a new child `PlumAtom` to this atom.
    ///
    /// It creates, initializes, and adds a new `PlumAtom` to the `children` map.
    ///
    /// Parameters:
    ///   - `allocator`: The memory allocator to create the new child atom.
    ///   - `key`: The path segment for the new child.
    ///
    /// Returns:
    ///   - A pointer to the newly created child `PlumAtom`.
    ///
    /// Errors:
    ///   - Can return errors from `allocator.create`, `PlumAtom.init`, or `self.children.put`.
    pub fn addChild(self: *PlumAtom, allocator: std.mem.Allocator, key: []const u8) !*PlumAtom {
        const child = try allocator.create(PlumAtom);
        child.* = try PlumAtom.init(allocator, key);
        try self.children.put(child.pure.path, child);
        return child;
    }

    /// Finds a direct child of this atom by its key (path segment).
    ///
    /// Parameters:
    ///   - `key`: The path segment of the child to find.
    ///
    /// Returns:
    ///   - An optional pointer to the child `PlumAtom` if found.
    pub fn findChild(self: *const PlumAtom, key: []const u8) ?*PlumAtom {
        return self.children.get(key);
    }
};
