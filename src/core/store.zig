//! PlumStore is the core data structure for PlumCache, acting as an in-memory key-value store.
//!
//! It is designed to handle two main types of data structures under a unified interface:
//! - **Atoms**: Simple key-value pairs for individual data entries, managed implicitly as trie leaves.
//! - **Tries**: Namespace-prefixed keys that are stored in a trie data structure,
//!   allowing for efficient prefix-based lookups and hierarchical data organization.
//!
//! The store manages a primary storage area where all data is held. It provides `set`, `get`,
//! and `delete` operations that abstract away the underlying trie implementation for simple
//! key-value interactions.
//!
//! A global singleton pattern is used to provide easy access to the `PlumStore` instance
//! throughout the application via `GetPlumStore()` and `InitPlumStore()`. This ensures a single
//! point of truth for the cache data.

const std = @import("std");
const atom = @import("atom.zig");
const trie = @import("trie.zig");
const intern = @import("intern.zig");
const tokenize = @import("../utils/tokenize.zig");

/// A global pointer to the `InternPool` instance. This interner is shared across
/// `Store` instances (and thus `PlumTrie` and `PlumAtom`) to deduplicate strings
/// like keys and path segments across the entire cache. It is initialized once
/// when the primary `Store` is set up.
var interner: *intern.InternPool = undefined;

/// `Store` is an internal data structure representing a single storage backend
/// within PlumCache. Currently, it primarily wraps a `PlumTrie` for all data operations.
///
/// It manages an allocator, an interner, and the `PlumTrie` itself.
const Store = struct {
    /// The memory allocator provided to this store, used for all its internal allocations.
    allocator: std.mem.Allocator,
    /// A pointer to the shared `InternPool` used for efficient string management.
    interner: *intern.InternPool,
    /// The underlying trie data structure where all key-value pairs are actually stored.
    collection: trie.PlumTrie,

    /// Initializes a new `Store` instance.
    ///
    /// This function sets up a shared `InternPool` and initializes the `PlumTrie`
    /// which will be used for storing data.
    ///
    /// Parameters:
    ///   - `allocator`: The memory allocator to use for creating the `InternPool`
    ///                  and initializing the `PlumTrie`.
    ///
    /// Returns:
    ///   - `!Store`: A new `Store` instance on success.
    ///
    /// Errors:
    ///   - Can return `error.OutOfMemory` if memory allocation fails for the `InternPool`
    ///     or `PlumTrie` initialization.
    pub fn init(allocator: std.mem.Allocator) !Store {
        // Allocate and initialize the global interner pool.
        interner = try allocator.create(intern.InternPool);
        interner.* = intern.InternPool.init(allocator);

        return Store{
            .allocator = allocator,
            .interner = interner,
            .collection = try trie.PlumTrie.init(allocator, interner),
        };
    }

    /// Deinitializes the `Store`, releasing all associated memory.
    ///
    /// This function deinitializes the underlying `PlumTrie` and the `InternPool`,
    /// ensuring all allocated resources are properly freed.
    ///
    /// Parameters:
    ///   - `self`: A pointer to the `Store` instance to be deinitialized.
    ///
    /// Returns:
    ///   - `void`
    pub fn deinit(self: *Store) void {
        self.interner.deinit();
        self.collection.deinit();
        // Free the memory for the interner struct itself, as it was `create`d.
        self.allocator.destroy(self.interner);
    }

    /// Sets or updates the value associated with the given key in this `Store`.
    ///
    /// This operation delegates directly to the underlying `PlumTrie`'s `set` method.
    ///
    /// Parameters:
    ///   - `self`: A pointer to the `Store` instance.
    ///   - `key`: A `[]const u8` slice representing the key to set.
    ///   - `value`: A `[]const u8` slice representing the value to associate with the key.
    ///
    /// Returns:
    ///   - `!void`: An empty result on success.
    ///
    /// Errors:
    ///   - Can return `error.OutOfMemory` if any underlying trie or atom operations
    ///     fail due to memory exhaustion.
    ///   - Can propagate other errors from `self.collection.set`.
    pub fn set(self: *Store, key: []const u8, value: []const u8) error{OutOfMemory}!void {
        self.collection.set(key, value) catch |err| {
            return err;
        };
    }

    /// Retrieves the value associated with the given key from this `Store`.
    ///
    /// This operation delegates directly to the underlying `PlumTrie`'s `get` method.
    ///
    /// Parameters:
    ///   - `self`: A pointer to the `Store` instance.
    ///   - `key`: A `[]const u8` slice representing the key to retrieve.
    ///
    /// Returns:
    ///   - `![]const u8`: The `[]const u8` slice representing the retrieved value on success.
    ///                   Returns `error.KeyNotFound` if the key does not exist.
    ///
    /// Errors:
    ///   - Can return `error.KeyNotFound` if the key is not present in the trie.
    ///   - Can propagate other errors from `self.collection.get`.
    pub fn get(self: *Store, key: []const u8) error{KeyNotFound}!?[]const u8 {
        if (try self.collection.get(key)) |value| {
            return value;
        } else {
            return error.KeyNotFound;
        }
    }

    /// Deletes the entry associated with the given key from this `Store`.
    ///
    /// This operation delegates directly to the underlying `PlumTrie`'s `delete` method.
    ///
    /// Parameters:
    ///   - `self`: A pointer to the `Store` instance.
    ///   - `key`: A `[]const u8` slice representing the key to delete.
    ///
    /// Returns:
    ///   - `!void`: An empty result on success.
    ///
    /// Errors:
    ///   - Can return `error.KeyNotFound` if the key is not present in the trie.
    ///   - Can propagate other errors from `self.collection.delete`.
    pub fn delete(self: *Store, key: []const u8) error{KeyNotFound}!void {
        try self.collection.delete(key) catch |err| {
            return err;
        };
    }
};

/// `plum_store` is a global variable that holds the single instance of `PlumStore`.
/// This makes `PlumStore` a singleton, accessible throughout the application.
/// It must be initialized once by `InitPlumStore` before use.
var plum_store: *PlumStore = undefined;

/// Returns the singleton instance of `PlumStore`.
///
/// This function should only be called after `InitPlumStore` has been successfully
/// invoked during application startup. Attempting to call it before initialization
/// will result in undefined behavior.
///
/// Returns:
///   - `*PlumStore`: A pointer to the global `PlumStore` instance.
pub fn GetPlumStore() *PlumStore {
    return plum_store;
}

/// Initializes the global singleton `PlumStore` instance.
///
/// This function allocates memory for `PlumStore`, initializes it using the provided
/// allocator, and assigns it to the global `plum_store` variable.
/// It should be called exactly once at the application's startup.
///
/// Parameters:
///   - `allocator`: The memory allocator to use for creating the `PlumStore` instance
///                  and its internal components.
///
/// Returns:
///   - `!void`: An empty result on success.
///
/// Errors:
///   - Can return `error.PlumStoreInitError` if initial allocation for `PlumStore` fails.
///   - Can propagate errors from `PlumStore.init` (e.g., `error.OutOfMemory` from internal `Store.init`).
pub fn InitPlumStore(allocator: std.mem.Allocator) !void {
    // Allocate memory for the global PlumStore instance.
    plum_store = allocator.create(PlumStore) catch return error.PlumStoreInitError;
    // Initialize the PlumStore instance. If initialization fails, destroy the
    // allocated memory and return the error.
    plum_store.* = PlumStore.init(allocator) catch |err| {
        allocator.destroy(plum_store);
        return err;
    };
}

/// `PlumStore` is the top-level public data structure that serves as PlumCache's
/// primary interface for client operations (SET, GET, DELETE).
///
/// It encapsulates one or more `Store` instances (currently just `primary_store`),
/// providing a unified API to interact with the underlying data storage mechanisms.
pub const PlumStore = struct {
    /// The memory allocator used by this `PlumStore` instance for its internal components.
    allocator: std.mem.Allocator,
    /// The primary storage backend, which uses a `PlumTrie` to store all data.
    primary_store: Store,

    /// Initializes a new `PlumStore` instance.
    ///
    /// This function initializes the `primary_store` component, which in turn sets up
    /// the `PlumTrie` and `InternPool`.
    ///
    /// Parameters:
    ///   - `allocator`: The memory allocator to use for initializing internal stores.
    ///
    /// Returns:
    ///   - `!PlumStore`: A new `PlumStore` instance on success.
    ///
    /// Errors:
    ///   - Can propagate errors from `Store.init` (e.g., `error.OutOfMemory`).
    pub fn init(allocator: std.mem.Allocator) !PlumStore {
        return PlumStore{
            .allocator = allocator,
            .primary_store = try Store.init(allocator),
        };
    }

    /// Deinitializes the `PlumStore`, releasing all resources.
    ///
    /// This function deinitializes all internal `Store` instances, ensuring that
    /// their associated memory (including tries and intern pools) is freed.
    ///
    /// Parameters:
    ///   - `self`: A pointer to the `PlumStore` instance to be deinitialized.
    ///
    /// Returns:
    ///   - `void`
    pub fn deinit(self: *PlumStore) void {
        self.primary_store.deinit();
    }

    /// Inserts or updates a key-value pair in the `PlumStore`.
    ///
    /// This function acts as the public interface for setting data. It delegates
    /// the actual storage operation to the `primary_store`'s `set` method, which
    /// handles the underlying trie logic.
    ///
    /// Parameters:
    ///   - `self`: A pointer to the `PlumStore` instance.
    ///   - `key`: The `[]const u8` key for the data. This can be a simple key or
    ///            a trie path (e.g., "namespace:path:to:value").
    ///   - `value`: The `[]const u8` value to associate with the key.
    ///
    /// Returns:
    ///   - `!void`: An empty result on success.
    ///
    /// Errors:
    ///   - Can return `error.OutOfMemory` if any underlying storage operation
    ///     fails due to insufficient memory.
    ///   - Can propagate other errors from `self.primary_store.set`.
    pub fn set(self: *PlumStore, key: []const u8, value: []const u8) error{OutOfMemory}!void {
        self.primary_store.set(key, value) catch |err| {
            switch (err) {
                error.OutOfMemory => return error.OutOfMemory,
                else => return err, // Re-throw other errors
            }
        };
    }

    /// Retrieves the value associated with the given key from the `PlumStore`.
    ///
    /// This function acts as the public interface for getting data. It delegates
    /// the actual retrieval operation to the `primary_store`'s `get` method.
    ///
    /// Parameters:
    ///   - `self`: A pointer to the `PlumStore` instance.
    ///   - `key`: The `[]const u8` key for the data to retrieve. This can be a
    ///            simple key or a trie path.
    ///
    /// Returns:
    ///   - `![]const u8`: The `[]const u8` slice representing the retrieved value
    ///                   on success.
    ///
    /// Errors:
    ///   - Can return `error.KeyNotFound` if the key does not exist in the store.
    ///   - Can propagate other errors from `self.primary_store.get`.
    pub fn get(self: *PlumStore, key: []const u8) ![]const u8 {
        if (try self.primary_store.get(key)) |value| {
            return value;
        } else {
            return error.KeyNotFound;
        }
    }

    /// Deletes the entry associated with the given key from the `PlumStore`.
    ///
    /// This function acts as the public interface for deleting data. It delegates
    /// the actual deletion operation to the `primary_store`'s `delete` method.
    ///
    /// Parameters:
    ///   - `self`: A pointer to the `PlumStore` instance.
    ///   - `key`: The `[]const u8` key of the entry to delete.
    ///
    /// Returns:
    ///   - `!void`: An empty result on success.
    ///
    /// Errors:
    ///   - Can return `error.KeyNotFound` if the key does not exist in the store.
    ///   - Can propagate other errors from `self.primary_store.delete`.
    pub fn delete(self: *PlumStore, key: []const u8) !void {
        try self.primary_store.delete(key) catch |err| {
            return err;
        };
    }
};
