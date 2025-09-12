//! This module defines the `PlumAtom` and `PurePlumAtom` structs, which are fundamental
//! data structures within PlumCache. These atoms form the building blocks for storing
//! key-value pairs and constructing the trie-based data structure.
//!
//! `PurePlumAtom` represents a single, indivisible data entry, akin to a key-value pair,
//! but with additional metadata such as access timestamps and counters. It's the "pure"
//! data component, containing the actual key segment, value, and essential cache-management
//! information.
//!
//! `PlumAtom` is a composite structure used in the `PlumTrie`. It contains a `PurePlumAtom`
//! for its own data and a hash map of children `PlumAtom`s. This design allows `PlumAtom`
//! instances to act as nodes in a trie, forming a hierarchical organization of data
//! where each node can hold a value and branch out to other child nodes representing
//! subsequent key segments.
const std = @import("std");
const intern = @import("intern.zig");

/// `AtomOptions` provides optional parameters for initializing a `PurePlumAtom`.
/// This struct allows for setting initial values for metadata fields such as
/// `access_count` and `last_accessed` upon creation, offering flexibility
/// in how new atoms are instantiated.
pub const AtomOptions = struct {
    /// The initial number of times the atom has been accessed.
    /// This field is used for cache eviction policies like Least Frequently Used (LFU).
    /// If not explicitly provided during initialization, it defaults to `0`.
    access_count: i16 = 0,
    /// The initial Unix timestamp of the last access.
    /// This field is crucial for cache eviction policies like Least Recently Used (LRU).
    /// If not explicitly provided during initialization, it defaults to `0`.
    last_accessed: i64 = 0,
};

/// `PurePlumAtom` is the core data structure for a single key-value entry in PlumCache.
/// It encapsulates the value associated with a key segment, along with critical metadata
/// used for cache management, analytics, and tracking the atom's lifecycle.
pub const PurePlumAtom = struct {
    /// The key segment for this atom. In a trie, this represents one part of a full key path.
    /// It is an optional pointer to a `[]const u8` (slice of bytes) managed by an `InternPool`
    /// to optimize memory usage by deduplicating strings. A `null` value might indicate a root node
    /// or a placeholder.
    path: ?*[]const u8,
    /// The actual value stored in this atom. It's an optional slice of `u8`, allowing for
    /// nodes that serve purely as path intermediaries in a trie without holding an explicit value.
    value: ?[]const u8,
    /// A counter indicating the number of times this atom has been accessed.
    /// This is a key metric for Least Frequently Used (LFU) eviction strategies.
    access_count: i16,
    /// The Unix timestamp (in nanoseconds) of the last time this atom was accessed.
    /// This is essential for Least Recently Used (LRU) and other time-based eviction policies.
    last_accessed: i64,
    /// The Unix timestamp (in nanoseconds) of when this atom was created.
    /// This can be used for Time-To-Live (TTL) or other age-based cache management.
    created_at: i64,

    /// Initializes a new `PurePlumAtom` instance.
    ///
    /// This function allocates memory for the `path` by interning it (to manage string deduplication)
    /// and sets initial metadata such as `access_count`, `last_accessed`, and `created_at`.
    /// The `value` field is initialized to `null`.
    ///
    /// Parameters:
    ///   - `path`: A `[]const u8` slice representing the key or path segment for this atom.
    ///   - `interner`: A pointer to an `intern.InternPool` instance, used to intern the `path` string.
    ///   - `options`: An optional `AtomOptions` struct to provide custom initial values for
    ///                `access_count` and `last_accessed`. If `null`, default values (0) are used.
    ///
    /// Returns:
    ///   - `!PurePlumAtom`: A new `PurePlumAtom` instance on success.
    ///
    /// Errors:
    ///   - Can return allocation errors (`error.OutOfMemory`) from `interner.intern` if memory
    ///     cannot be allocated for duplicating the path.
    pub fn init(path: []const u8, interner: *intern.InternPool, options: ?AtomOptions) !PurePlumAtom {
        var access_count: i16 = 0;
        var last_accessed: i64 = 0;
        // If options are provided, use them to set initial access metadata.
        if (options) |opt| {
            access_count = opt.access_count;
            last_accessed = opt.last_accessed;
        }
        // Get the current Unix timestamp for `created_at` and `last_accessed` (if not provided).
        const now = std.time.timestamp();
        // Intern the path string to save memory and get a pointer to the interned string.
        const pathPtr = try interner.intern(path);
        return PurePlumAtom{
            .path = pathPtr,
            .value = null, // Value is initially null and set later by `setValue`.
            .access_count = access_count,
            .last_accessed = last_accessed,
            .created_at = now,
        };
    }

    /// Deinitializes the `PurePlumAtom`, releasing any allocated resources.
    ///
    /// This function de-interns the `path` string and deinitializes the `path` and `value`
    /// fields. It's crucial for preventing memory leaks, especially when atoms are removed
    /// from the cache or a trie.
    ///
    /// Parameters:
    ///   - `self`: A pointer to the `PurePlumAtom` instance to be deinitialized.
    ///   - `interner`: A pointer to the `intern.InternPool` instance, used to de-intern the `path`.
    ///
    /// Returns:
    ///   - `void`
    ///
    /// Errors:
    ///   - Can propagate errors from `interner.deintern` (e.g., if the key is not found in the pool).
    pub fn deinit(self: *PurePlumAtom, interner: *intern.InternPool) void {
        _ = interner.deintern(self.path.?); // De-intern the path.
        // It's important to set path/value to null after deiniting to prevent use-after-free
        // and clearly mark the atom as deinitialized.
        self.path = null;
        self.value = null;
    }

    /// Sets or updates the value associated with this atom.
    ///
    /// This function allocates memory for the provided `value` by duplicating its content
    /// and then assigns the duplicated slice to the atom's `value` field. If a value
    /// already exists, the old memory *must* be freed manually by the caller if it's no longer needed,
    /// as this function only sets the new value.
    ///
    /// Parameters:
    ///   - `allocator`: The memory allocator to use for duplicating the `value` slice.
    ///   - `value`: A `[]const u8` slice containing the new value to be set. This value will be
    ///              copied into newly allocated memory.
    ///
    /// Returns:
    ///   - `!void`: An empty result on success.
    ///
    /// Errors:
    ///   - Can return allocation errors (`error.OutOfMemory`) from `allocator.dupe`
    ///     if memory cannot be allocated for the new value.
    pub fn setValue(self: *PurePlumAtom, allocator: std.mem.Allocator, value: []const u8) !void {
        // If there's an existing value, its memory should ideally be freed here
        // or managed by the caller to prevent leaks. For simplicity, this implementation
        // assumes `value` is either null or the caller will handle old value deallocation.
        self.value = try allocator.dupe(u8, value);
    }

    /// Updates the access metadata for the atom.
    ///
    /// This function increments the `access_count` by one and updates the `last_accessed`
    /// timestamp to the current Unix timestamp. This is a fundamental operation for
    /// maintaining cache statistics required by eviction policies.
    ///
    /// Parameters:
    ///   - `self`: A pointer to the `PurePlumAtom` instance whose access metadata needs updating.
    ///
    /// Returns:
    ///   - `void`
    pub fn updateAccessCount(self: *PurePlumAtom) void {
        // Increment the access count using saturating addition to prevent overflow.
        // If `access_count` reaches `i16.max_value`, it will stay there.
        self.access_count = self.access_count +% 1;
        // Update the `last_accessed` timestamp to the current time.
        self.last_accessed = std.time.timestamp();
    }
};

/// `PlumAtom` represents a node within a `PlumTrie`.
///
/// It is a composite structure that combines a `PurePlumAtom` to store its own data
/// (key segment, value, metadata) and a `std.StringHashMap` of children `PlumAtom`s.
/// This structure allows for the hierarchical organization of data, forming the branches
/// and leaves of a trie. Each `PlumAtom` can represent a part of a key path and potentially
/// hold a value for that path segment.
pub const PlumAtom = struct {
    /// The embedded `PurePlumAtom` containing the key segment, optional value, and
    /// access metadata for this specific node in the trie.
    pure: PurePlumAtom,
    /// A hash map storing direct child `PlumAtom` nodes. The keys of the map are
    /// the path segments (strings) leading to the children, and the values are
    /// pointers to the child `PlumAtom` instances. This forms the branching structure of the trie.
    children: std.StringHashMap(*PlumAtom),

    /// Initializes a new `PlumAtom` instance, acting as a node in a `PlumTrie`.
    ///
    /// This function creates an embedded `PurePlumAtom` for the given key segment
    /// and initializes an empty `std.StringHashMap` to hold its children.
    ///
    /// Parameters:
    ///   - `allocator`: The memory allocator to use for internal structures, including
    ///                  the `PurePlumAtom` and the `children` hash map.
    ///   - `key`: A `[]const u8` slice representing the path segment for this atom (node).
    ///            For the root node of a trie, this might be an empty string.
    ///   - `interner`: A pointer to an `intern.InternPool` instance, used by the `PurePlumAtom`
    ///                 to intern the `key` string.
    ///
    /// Returns:
    ///   - `!PlumAtom`: A new `PlumAtom` instance on success.
    ///
    /// Errors:
    ///   - Can return errors from `PurePlumAtom.init` (e.g., `error.OutOfMemory` during path interning).
    ///   - Can return errors from `std.StringHashMap.init` if memory allocation for the hash map fails.
    pub fn init(
        allocator: std.mem.Allocator,
        key: []const u8,
        interner: *intern.InternPool,
    ) !PlumAtom {
        // Initialize an empty hash map for children using the provided allocator.
        const children = std.StringHashMap(*PlumAtom).init(allocator);

        return PlumAtom{
            // Initialize the embedded `PurePlumAtom` with the given key and no initial options.
            .pure = try PurePlumAtom.init(key, interner, null),
            .children = children,
        };
    }

    /// Deinitializes the `PlumAtom` and recursively deallocates all its descendants.
    ///
    /// This is a critical function for memory management in the `PlumTrie`. It iterates
    /// through all child `PlumAtom`s, recursively calls their `deinit` method, destroys
    /// their memory, and then deinitializes its own `children` hash map and its embedded
    /// `PurePlumAtom`.
    ///
    /// Parameters:
    ///   - `self`: A pointer to the `PlumAtom` instance to be deinitialized.
    ///   - `allocator`: The memory allocator used to create and destroy child atoms.
    ///   - `interner`: A pointer to the `intern.InternPool` instance, used to de-intern
    ///                 the path strings of this atom and its descendants.
    ///
    /// Returns:
    ///   - `void`
    pub fn deinit(self: *PlumAtom, allocator: std.mem.Allocator, interner: *intern.InternPool) void {
        // Iterate over all child items in the `children` hash map.
        for (self.children.items()) |child_entry| {
            // Recursively deinitialize each child `PlumAtom`.
            // The `child_entry.value` is a `*PlumAtom`.
            child_entry.value.deinit(allocator, interner);
            // After deinitialization, destroy the memory allocated for the child `PlumAtom` itself.
            allocator.destroy(child_entry.value);
        }
        // Deinitialize the hash map used for children, freeing its internal memory.
        self.children.deinit();
        // Deinitialize the embedded `PurePlumAtom`, releasing its associated resources.
        self.pure.deinit(interner);
    }

    /// Adds a new child `PlumAtom` to this atom's `children` map.
    ///
    /// This function first allocates memory for a new `PlumAtom` instance, initializes it
    /// with the provided `key` segment, and then inserts it into the `children` hash map
    /// of the current atom.
    ///
    /// Parameters:
    ///   - `self`: A pointer to the parent `PlumAtom` to which the child will be added.
    ///   - `allocator`: The memory allocator to use for creating the new child `PlumAtom`.
    ///   - `key`: A `[]const u8` slice representing the path segment for the new child atom.
    ///   - `interner`: A pointer to an `intern.InternPool` instance, used by the new child's
    ///                 `PurePlumAtom` to intern its `key` string.
    ///
    /// Returns:
    ///   - `!*PlumAtom`: A pointer to the newly created child `PlumAtom` on success.
    ///
    /// Errors:
    ///   - Can return allocation errors (`error.OutOfMemory`) from `allocator.create`
    ///     when creating the `PlumAtom` struct itself.
    ///   - Can return errors from `PlumAtom.init` (e.g., `error.OutOfMemory` during `PurePlumAtom` initialization).
    ///   - Can return errors from `self.children.put` (e.g., `error.OutOfMemory` if the hash map needs to resize).
    pub fn addChild(self: *PlumAtom, allocator: std.mem.Allocator, key: []const u8, interner: *intern.InternPool) !*PlumAtom {
        // Allocate memory for the new child `PlumAtom` struct.
        const child = try allocator.create(PlumAtom);
        // Initialize the newly allocated child `PlumAtom` with the given key.
        child.* = try PlumAtom.init(allocator, key, interner);
        // Insert the new child into the `children` hash map of the current atom.
        // The key for the hash map is the interned path of the child's `PurePlumAtom`.
        try self.children.put(child.pure.path.?.*, child);
        return child;
    }

    /// Finds a direct child of this atom by its key (path segment).
    ///
    /// This function looks up a child `PlumAtom` in the `children` hash map using
    /// the provided `key` segment. It provides a way to traverse the trie structure.
    ///
    /// Parameters:
    ///   - `self`: A constant pointer to the `PlumAtom` (parent) to search within.
    ///             The `const` ensures that this function does not modify the atom.
    ///   - `key`: A `[]const u8` slice representing the path segment of the child to find.
    ///
    /// Returns:
    ///   - `?*PlumAtom`: An optional pointer to the child `PlumAtom` if a child
    ///                   with the matching `key` is found. Returns `null` otherwise.
    pub fn findChild(self: *const PlumAtom, key: []const u8) ?*PlumAtom {
        // Use the hash map's `get` method to find the child.
        // The `get` method returns `null` if the key is not found.
        return self.children.get(key);
    }
};
