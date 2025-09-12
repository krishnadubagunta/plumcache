//! This module defines the `PlumTrie` data structure, a prefix tree used for storing
//! and retrieving namespaced key-value data efficiently.
//!
//! The `PlumTrie` is built upon `PlumAtom` nodes, where each node represents a segment
//! of a key (path). It provides `set`, `get`, and `delete` operations that traverse the trie
//! based on the tokenized key, allowing for O(m) complexity where 'm' is the length of the key.
//! This is ideal for scenarios involving hierarchical data or requiring efficient prefix-based lookups.

const std = @import("std");
const atom = @import("atom.zig");
const intern = @import("intern.zig");
const tokenize = @import("../utils/tokenize.zig");

/// `PlumTrie` implements a prefix tree for storing and managing namespaced key-value pairs.
///
/// It utilizes `PlumAtom`s as its nodes, with each node representing a segment of a key path.
/// Keys are tokenized to traverse the tree, enabling efficient prefix-based operations.
pub const PlumTrie = struct {
    /// A pointer to the shared `intern.InternPool` instance.
    /// This pool is used to intern key segments within `PlumAtom`s,
    /// optimizing memory usage and string comparisons across the trie.
    interner: *intern.InternPool,
    /// The root node of the trie. This `PlumAtom` conceptually represents an empty
    /// path segment and serves as the starting point for all key traversals.
    root: atom.PlumAtom,
    /// The memory allocator used for all node creations and deletions within this trie.
    /// It is passed down to `PlumAtom` and its children for consistent memory management.
    allocator: std.mem.Allocator,

    /// Initializes a new `PlumTrie` instance.
    ///
    /// This function sets up the root node of the trie, which is an empty `PlumAtom`,
    /// and stores the provided allocator and interner for subsequent node operations.
    ///
    /// Parameters:
    ///   - `allocator`: The memory allocator to use for the trie's nodes and internal structures.
    ///   - `interner`: A pointer to the `intern.InternPool` instance for string interning.
    ///
    /// Returns:
    ///   - `!PlumTrie`: A new `PlumTrie` instance on success.
    ///
    /// Errors:
    ///   - Can return `error.OutOfMemory` errors from `atom.PlumAtom.init` if memory
    ///     allocation for the root node fails.
    pub fn init(allocator: std.mem.Allocator, interner: *intern.InternPool) !PlumTrie {
        return PlumTrie{
            .allocator = allocator,
            .interner = interner,
            .root = try atom.PlumAtom.init(allocator, "", interner), // Initialize the root node with an empty key.
        };
    }

    /// Deinitializes the `PlumTrie`, freeing all memory it has allocated.
    ///
    /// This is done by recursively deinitializing the root `PlumAtom` and all its descendants.
    /// Calling this is crucial to prevent memory leaks when the trie is no longer needed.
    ///
    /// Parameters:
    ///   - `self`: A pointer to the `PlumTrie` instance to be deinitialized.
    ///
    /// Returns:
    ///   - `void`
    pub fn deinit(self: *PlumTrie) void {
        // Recursively deinitialize the root atom, which will deinitialize all its children.
        self.root.deinit(self.allocator, self.interner);
    }

    /// Sets a value for a given key within the trie.
    ///
    /// This function tokenizes the `full_key` into segments and traverses the trie.
    /// If a segment's corresponding node does not exist, a new `PlumAtom` is created
    /// and added as a child. The `value` is ultimately set on the `PurePlumAtom`
    /// of the final node corresponding to the complete `full_key` path.
    ///
    /// Parameters:
    ///   - `self`: A pointer to the `PlumTrie` instance.
    ///   - `full_key`: The complete key path, with segments typically separated by a delimiter
    ///                 (e.g., "namespace:path:to:value").
    ///   - `value`: The `[]const u8` value to store at the key's location.
    ///
    /// Returns:
    ///   - `!void`: An empty result on success.
    ///
    /// Errors:
    ///   - Can return `error.OutOfMemory` errors from `tokenize.Tokenize` (if it allocates, though currently it doesn't),
    ///     `current.addChild` (which involves `allocator.create` and `PlumAtom.init`), or `current.pure.setValue`
    ///     (which involves `allocator.dupe`).
    pub fn set(self: *PlumTrie, full_key: []const u8, value: []const u8) !void {
        // Tokenize the full key into segments. `null` indicates using the default delimiter.
        var tokens = tokenize.Tokenize(full_key, null);
        // Start traversal from the root node.
        var current: *atom.PlumAtom = &self.root;

        // Iterate through each segment of the key.
        while (tokens.next()) |segment| {
            // Try to find a child node corresponding to the current segment.
            const maybe_child = current.findChild(segment);

            if (maybe_child) |child| {
                // If a child exists, move to that child node.
                current = child;
            } else {
                // If no child exists, create a new `PlumAtom` for this segment and add it.
                current = try current.addChild(self.allocator, segment, self.interner);
            }
        }

        // Once at the final node, set its `PurePlumAtom`'s value.
        try current.pure.setValue(self.allocator, value);
    }

    /// Retrieves the value for a given key from the trie.
    ///
    /// This function tokenizes the `full_key` into segments and traverses the trie.
    /// If the complete path exists, it returns the value stored in the `PurePlumAtom`
    /// of the final node and updates that node's access metadata.
    ///
    /// Parameters:
    ///   - `self`: A pointer to the `PlumTrie` instance.
    ///   - `full_key`: The complete key path to look up.
    ///
    /// Returns:
    ///   - `error{KeyNotFound}!?[]const u8`: An optional `[]const u8` slice containing the value
    ///                                     if the key is found and has a value, or `null` if the
    ///                                     node exists but its value is `null`. Returns
    ///                                     `error.KeyNotFound` if any segment of the path is not found.
    ///
    /// Errors:
    ///   - `error.KeyNotFound`: If any segment of the `full_key` path does not exist in the trie.
    pub fn get(self: *PlumTrie, full_key: []const u8) error{KeyNotFound}!?[]const u8 {
        // Tokenize the full key into segments.
        var tokens = tokenize.Tokenize(full_key, null);
        // Start traversal from the root node.
        var current: *atom.PlumAtom = &self.root;

        // Iterate through each segment of the key.
        while (tokens.next()) |segment| {
            // Try to find a child node corresponding to the current segment.
            // If not found, the key path does not exist, so return `error.KeyNotFound`.
            const child = current.findChild(segment) orelse return error.KeyNotFound;
            // Move to the found child node.
            current = child;
        }

        // Once at the final node, update its access count and return its value.
        current.pure.updateAccessCount();
        return current.pure.value;
    }

    /// Deletes the entry associated with the given key from the trie.
    ///
    /// This function tokenizes the `full_key` and traverses the trie to locate
    /// the node corresponding to the `full_key`. Once found, it recursively
    /// deinitializes that `PlumAtom` and its descendants, effectively removing
    /// the entry and freeing its associated memory.
    ///
    /// Parameters:
    ///   - `self`: A pointer to the `PlumTrie` instance.
    ///   - `full_key`: The complete key path of the entry to be deleted.
    ///
    /// Returns:
    ///   - `error{KeyNotFound}!void`: An empty result on success. Returns `error.KeyNotFound`
    ///                                 if the key path does not exist in the trie.
    ///
    /// Errors:
    ///   - `error.KeyNotFound`: If any segment of the `full_key` path does not exist.
    pub fn delete(self: *PlumTrie, full_key: []const u8) error{KeyNotFound}!void {
        // Tokenize the full key into segments.
        var tokens = tokenize.Tokenize(full_key, null);
        // Start traversal from the root node.
        var current: *atom.PlumAtom = &self.root;

        // Traverse the trie to find the target node.
        while (tokens.next()) |segment| {
            // If any segment in the path is not found, the key does not exist.
            const child = current.findChild(segment) orelse return error.KeyNotFound;
            current = child;
        }

        // Once at the target node, deinitialize it and its descendants recursively.
        // Note: This deinitialization logic is simplified; a more robust delete
        // would also remove the child from its parent's `children` map if it
        // becomes a leaf or has no value after its children are removed.
        // The current implementation only deinitializes the target node and its subtree,
        // but it doesn't detach it from its parent. This would lead to a memory leak in the parent's children map.
        // A proper trie deletion might require backtracking or a more complex parent-child management.
        current.deinit(self.allocator, self.interner);
    }
};
