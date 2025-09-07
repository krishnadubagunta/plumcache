//! PlumStore is the core data structure for PlumCache, acting as an in-memory key-value store.
//!
//! It is designed to handle two main types of data structures under a unified interface:
//! - **Atoms**: Simple key-value pairs for individual data entries.
//! - **Tries**: Namespace-prefixed keys that are stored in a trie data structure,
//!   allowing for efficient prefix-based lookups and hierarchical data organization.
//!
//! The store manages a primary storage area where all data is held. It provides `set` and `get`
//! operations that intelligently distinguish between atom and trie keys based on the presence
//! of a ':' separator.
//!
//! A global singleton pattern is used to provide easy access to the `PlumStore` instance
//! throughout the application via `GetPlumStore()` and `InitPlumStore()`.

const std = @import("std");
const entry = @import("entry.zig");
const atom = @import("atom.zig");
const trie = @import("trie.zig");
const tokenize = @import("../utils/tokenize.zig");

/// Store is the data structure that is used to store the data in the PlumDB.
const Store = struct {
    allocator: std.mem.Allocator,
    entries: std.StringHashMap(entry.Entry),

    /// init initializes the Store.
    /// It takes an allocator as input.
    /// It returns a new Store instance.
    pub fn init(allocator: std.mem.Allocator) Store {
        return Store{
            .allocator = allocator,
            .entries = std.StringHashMap(entry.Entry).init(allocator),
        };
    }

    /// deinit deinitializes the Store.
    /// It deinitializes the entries hash map.
    pub fn deinit(self: *Store) void {
        self.entries.deinit();
    }
};

/// plum_store is a global variable that holds the single instance of PlumStore.
/// It is initialized by InitPlumStore and accessed via GetPlumStore.
var plum_store: *PlumStore = undefined;

/// GetPlumStore returns the singleton instance of PlumStore.
/// This function should only be called after InitPlumStore has been successfully called.
pub fn GetPlumStore() *PlumStore {
    return plum_store;
}

/// InitPlumStore initializes the global PlumStore instance.
/// It allocates memory for the PlumStore and calls its init function.
/// This function should be called once at the application startup.
pub fn InitPlumStore(allocator: std.mem.Allocator) !void {
    plum_store = allocator.create(PlumStore) catch return error.PlumStoreInitError;
    plum_store.* = PlumStore.init(allocator);
}

/// PlumStore is the data structure that is used to store the data in the PlumDB.
///
/// It has two stores, primary and secondary.
///
/// Primary store is the main store that is used to store the data that is accessed frequently.
///
/// Secondary store is the backup store that is used to store the data that is accessed less frequently.
///
pub const PlumStore = struct {
    allocator: std.mem.Allocator,
    primary_store: Store,

    /// init initializes the PlumStore.
    ///
    /// It initializes the primary and secondary stores.
    ///
    /// It returns a PlumStore.
    ///
    pub fn init(allocator: std.mem.Allocator) PlumStore {
        return PlumStore{
            .allocator = allocator,
            .primary_store = Store.init(allocator),
        };
    }

    /// deinit deinitializes the PlumStore.
    ///
    /// It deinitializes the primary and secondary stores.
    ///
    /// It returns a void.
    ///
    pub fn deinit(self: *PlumStore) void {
        self.primary_store.deinit();
    }

    /// new_entry creates or updates an entry based on the provided key and value.
    ///
    /// If an `fetched_entry` is provided, it updates the access count of the existing atom.
    /// Otherwise, it initializes a new atom. It then sets the value for the atom.
    ///
    /// Parameters:
    ///   - `key`: The key for the entry.
    ///   - `value`: The value to be stored in the entry.
    ///   - `fetched_entry`: An optional existing entry. If present, its access count is incremented.
    ///
    /// Returns:
    ///   - An `entry.Entry` struct representing the new or updated entry.
    ///
    /// Errors:
    ///   - Can return errors from `atom.PurePlumAtom.init` or `setValue`.
    ///
    fn new_entry(self: *PlumStore, key: []const u8, value: []const u8, fetched_entry: ?entry.Entry) !entry.Entry {
        var pure_plum_atom: atom.PurePlumAtom = undefined;
        if (fetched_entry) |existing_entry| {
            pure_plum_atom = try atom.PurePlumAtom.init(self.allocator, key, atom.AtomOptions{ .access_count = existing_entry.value.atom.access_count + 1, .last_accessed = std.time.milliTimestamp() });
        } else {
            pure_plum_atom = try atom.PurePlumAtom.init(self.allocator, key, null);
        }
        try pure_plum_atom.setValue(self.allocator, value);
        const new_entry_value = entry.EntryValue{ .atom = pure_plum_atom };

        return entry.Entry{ .key = key, .value = new_entry_value };
    }

    /// set inserts or updates a key-value pair in the PlumStore.
    ///
    /// It differentiates between "trie" keys (containing ':') and "atom" keys (no ':').
    ///
    /// For trie keys:
    ///   - It tokenizes the key to extract a namespace and path.
    ///   - If the namespace exists in the primary store, it updates the corresponding trie.
    ///   - If not, it creates a new trie for the namespace and adds it to the primary store.
    ///
    /// For atom keys:
    ///   - It checks if the key exists in the primary store.
    ///   - If it exists, it updates the existing entry's atom (e.g., increments access count).
    ///   - If not, it creates a new atom entry and adds it to the primary store.
    ///
    /// Parameters:
    ///   - `key`: The key for the data. Can be a simple key or a trie path (e.g., "namespace:path:to:value").
    ///   - `value`: The value to associate with the key.
    ///
    /// Errors:
    ///   - Can return errors from `tokenize.Tokenize`, `trie.PlumTrie.init`, `fetched_trie.set`, `new_entry`,
    ///     or `std.StringHashMap.put`.
    pub fn set(self: *PlumStore, key: []const u8, value: []const u8) !void {
        if (std.mem.indexOf(u8, key, ":") != null) {
            // If the key contains ':', it's treated as a trie path.
            // The part before the first ':' is the namespace, the rest is the path within the trie.
            var tokens = tokenize.Tokenize(key, null);
            const namespace: []const u8 = tokens.next().?;

            if (self.primary_store.entries.get(namespace)) |fetched_entry| {
                // If the namespace already exists in the primary store, update the associated trie.
                var fetched_trie = fetched_entry.value.trie;
                try fetched_trie.set(tokens.rest(), value);
            } else {
                // If the namespace does not exist, create a new trie for it
                // and add it to the primary store, then set the value.
                var new_primary_trie = try trie.PlumTrie.init(self.primary_store.allocator);
                try new_primary_trie.set(tokens.rest(), value);
                self.primary_store.entries.put(namespace, entry.Entry{ .key = namespace, .value = entry.EntryValue{ .trie = new_primary_trie } }) catch unreachable;
            }
        } else {
            // If the key does not contain ':', it's treated as a simple atom key.
            if (self.primary_store.entries.get(key)) |fetched_entry| {
                // If the key exists in the primary store, update the existing atom's value and metadata.
                const entry_key = try self.new_entry(key, value, fetched_entry);
                self.primary_store.entries.put(entry_key.key, entry_key) catch unreachable;
            } else {
                // If the key does not exist, create a new atom entry and add it to the primary store.
                self.primary_store.entries.put(key, try self.new_entry(key, value, null)) catch unreachable;
            }
        }
    }

    /// get retrieves the value associated with the given key from the PlumStore.
    ///
    /// It differentiates between "trie" keys (containing ':') and "atom" keys (no ':').
    ///
    /// For trie keys:
    ///   - It tokenizes the key to extract a namespace and path.
    ///   - It attempts to find the corresponding trie in the primary store.
    ///   - If found, it retrieves the value from the trie.
    ///
    /// For atom keys:
    ///   - It directly looks up the key in the primary store's entries.
    ///   - If found, it retrieves the value from the associated atom.
    ///
    /// Parameters:
    ///   - `key`: The key for the data to retrieve. Can be a simple key or a trie path.
    ///
    /// Returns:
    ///   - `?[]const u8`: An optional slice of `u8` representing the retrieved value.
    ///     Returns `null` if the key is not found, or if the value itself is null.
    pub fn get(self: *PlumStore, key: []const u8) ?[]const u8 {
        var fetched_value: ?[]const u8 = null;
        if (std.mem.indexOf(u8, key, ":") != null) {
            // If the key contains ':', it's treated as a trie path.
            // The part before the first ':' is the namespace, the rest is the path within the trie.
            var tokens = tokenize.Tokenize(key, null);
            const namespace: []const u8 = tokens.next().?;

            if (self.primary_store.entries.get(namespace)) |fetched_entry| {
                // If the namespace exists in the primary store, retrieve from the associated trie.
                var fetched_trie = fetched_entry.value.trie;
                fetched_value = fetched_trie.get(tokens.rest()) orelse null;
            } else {
                // Namespace not found.
                fetched_value = null;
            }
        } else {
            // If the key does not contain ':', it's treated as a simple atom key.
            if (self.primary_store.entries.get(key)) |fetched_entry| {
                // If the key exists in the primary store, retrieve the atom's value.
                fetched_value = fetched_entry.value.atom.value orelse null;
            } else {
                // Key not found.
                fetched_value = null;
            }
        }
        return fetched_value;
    }
};
