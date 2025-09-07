//! This module defines the `PlumTrie` data structure, a prefix tree used for storing
//! and retrieving namespaced key-value data efficiently.
//!
//! The `PlumTrie` is built upon `PlumAtom` nodes, where each node represents a segment
//! of a key (path). It provides `set` and `get` operations that traverse the trie
//! based on the tokenized key, allowing for O(m) complexity where 'm' is the length of the key.
//! This is ideal for scenarios involving hierarchical data or requiring efficient prefix-based lookups.

const std = @import("std");
const atom = @import("atom.zig");
const tokenize = @import("../utils/tokenize.zig");

/// `PlumTrie` implements a prefix tree for storing and managing namespaced key-value pairs.
/// It uses `PlumAtom`s as its nodes and tokenizes keys to traverse the tree.
pub const PlumTrie = struct {
    /// The root node of the trie, which is an empty `PlumAtom`.
    root: atom.PlumAtom,
    /// The memory allocator used for all node creations and deletions within this trie.
    allocator: std.mem.Allocator,

    /// Initializes a new `PlumTrie`.
    ///
    /// It creates an empty root node to serve as the starting point for all paths.
    ///
    /// Parameters:
    ///   - `allocator`: The memory allocator for the trie's nodes.
    ///
    /// Returns:
    ///   - A new `PlumTrie` instance.
    ///
    /// Errors:
    ///   - Can return errors from `atom.PlumAtom.init`.
    pub fn init(allocator: std.mem.Allocator) !PlumTrie {
        return PlumTrie{
            .allocator = allocator,
            .root = try atom.PlumAtom.init(allocator, ""),
        };
    }

    /// Deinitializes the `PlumTrie`, freeing all memory it has allocated.
    /// This is done by recursively deinitializing the root `PlumAtom` and all its descendants.
    pub fn deinit(self: *PlumTrie) void {
        self.root.deinit(self.allocator);
    }

    /// Sets a value for a given key within the trie.
    ///
    /// It tokenizes the `full_key` and traverses the trie, creating new nodes (`PlumAtom`s)
    /// as needed. The `value` is set on the final node corresponding to the full key path.
    ///
    /// Parameters:
    ///   - `full_key`: The complete key path, with segments separated by ':'.
    ///   - `value`: The value to store at the key's location.
    ///
    /// Errors:
    ///   - Can return errors from `tokenize.Tokenize`, `current.addChild`, or `current.pure.setValue`.
    pub fn set(self: *PlumTrie, full_key: []const u8, value: []const u8) !void {
        var tokens = tokenize.Tokenize(full_key, null);
        var current: *atom.PlumAtom = &self.root;

        while (tokens.next()) |segment| {
            const maybe_child = current.findChild(segment);

            if (maybe_child) |child| {
                current = child;
            } else {
                current = try current.addChild(self.allocator, segment);
            }
        }

        try current.pure.setValue(self.allocator, value);
    }

    /// Retrieves the value for a given key from the trie.
    ///
    /// It tokenizes the `full_key` and traverses the trie. If the path exists, it returns
    /// the value of the final node and updates its access metadata.
    ///
    /// Parameters:
    ///   - `full_key`: The complete key path to look up.
    ///
    /// Returns:
    ///   - An optional slice of `u8` with the value if the key is found, otherwise `null`.
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
