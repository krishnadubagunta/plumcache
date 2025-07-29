//! SyvoreStore is the data structure that is used to store the data in the SyvoreDB.
//!
//! It is a key-value store that is used to store the data in the SyvoreDB.
//!
//! It has two stores, primary and secondary.
//!
//! Primary store is the main store that is used to store the data.
//!
//! Secondary store is the backup store that is used to store the data.
//!
//! The primary store is used to store the data that is accessed frequently.
//!

const std = @import("std");
const entry = @import("entry.zig");
const atom = @import("atom.zig");
const trie = @import("trie.zig");
const tokenize = @import("../utils/tokenize.zig");

/// Store is the data structure that is used to store the data in the SyvoreDB.
const Store = struct {
    allocator: *std.mem.Allocator,
    entries: std.StringHashMap(entry.Entry),

    pub fn init(allocator: *std.mem.Allocator) Store {
        return Store{
            .allocator = allocator,
            .entries = std.StringHashMap(entry.Entry).init(allocator.*),
        };
    }

    pub fn deinit(self: *Store) void {
        self.entries.deinit();
    }
};

var syvore_store: *SyvoreStore = undefined;

pub fn GetSyvoreStore() *SyvoreStore {
    return syvore_store;
}

pub fn InitSyvoreStore(allocator: *std.mem.Allocator) !void {
    syvore_store.* = SyvoreStore.init(allocator);
}

/// SyvoreStore is the data structure that is used to store the data in the SyvoreDB.
///
/// It has two stores, primary and secondary.
///
/// Primary store is the main store that is used to store the data that is accessed frequently.
///
/// Secondary store is the backup store that is used to store the data that is accessed less frequently.
///
pub const SyvoreStore = struct {
    primary_store: Store,
    secondary_store: Store,

    /// init initializes the SyvoreStore.
    ///
    /// It initializes the primary and secondary stores.
    ///
    /// It returns a SyvoreStore.
    ///
    pub fn init(allocator: *std.mem.Allocator) SyvoreStore {
        return SyvoreStore{
            .primary_store = Store.init(allocator),
            .secondary_store = Store.init(allocator),
        };
    }

    /// deinit deinitializes the SyvoreStore.
    ///
    /// It deinitializes the primary and secondary stores.
    ///
    /// It returns a void.
    ///
    pub fn deinit(self: *SyvoreStore) void {
        self.primary_store.deinit();
        self.secondary_store.deinit();
    }

    /// get_entry gets the entry for the given key.
    ///
    /// It gets the entry for the given key.
    ///
    /// It returns an entry.Entry.
    ///
    fn get_entry(_: *SyvoreStore, key: []const u8, value: []const u8, fetched_entry: ?entry.Entry) entry.Entry {
        var pure_value: atom.PureSyvoreAtom = undefined;
        if (fetched_entry) |existing_entry| {
            pure_value = atom.PureSyvoreAtom.init(key, value, atom.AtomOptions{ .access_count = existing_entry.value.atom.access_count + 1, .last_accessed = std.time.milliTimestamp() });
        } else {
            pure_value = atom.PureSyvoreAtom.init(key, value, null);
        }
        const new_entry_value = entry.EntryValue{ .atom = pure_value };
        const new_entry = entry.Entry{ .key = key, .value = new_entry_value };

        return new_entry;
    }

    /// SET sets the value for the given key.
    pub fn set(self: *SyvoreStore, key: []const u8, value: []const u8) !void {
        if (std.mem.indexOf(u8, key, ":") != null) {
            // If : exists, then it's a trie. Now figure out if the index key exists in the entries of primary store first.
            // If it doesn't, check secondary store and upgrade it to primary store if it exists.
            // If it doesn't exist in secondary store, create a new trie and set the value in the primary store.
            // If it exists in both stores, then update the value in the primary store.
            var tokens = tokenize.Tokenize(key, null);
            const namespace: []const u8 = tokens.next().?;

            if (self.primary_store.entries.get(namespace)) |fetched_entry| {
                // If it exists in the primary store, then update the value in the primary store.
                var fetched_trie = fetched_entry.value.trie;
                try fetched_trie.set(tokens.rest(), value);
            } else if (self.secondary_store.entries.get(namespace)) |fetched_entry| {
                var fetched_trie = fetched_entry.value.trie;
                var new_primary_trie = try trie.SyvoreTrie.init(self.primary_store.allocator);
                try new_primary_trie.set(tokens.rest(), value);
                fetched_trie.deinit();
                _ = self.secondary_store.entries.remove(namespace);
                self.primary_store.entries.put(namespace, entry.Entry{ .key = namespace, .value = entry.EntryValue{ .trie = new_primary_trie } }) catch unreachable;
            } else {
                var new_primary_trie = try trie.SyvoreTrie.init(self.primary_store.allocator);
                try new_primary_trie.set(tokens.rest(), value);
                self.primary_store.entries.put(namespace, entry.Entry{ .key = namespace, .value = entry.EntryValue{ .trie = new_primary_trie } }) catch unreachable;
            }
        } else {
            // Now check if the key exists in the entries of primary store.
            // If it doesn't, check secondary store and upgrade it to primary store if it exists.
            // If it doesn't exist in secondary store, create a new entry and set the value in the primary store.

            if (self.primary_store.entries.get(key)) |fetched_entry| {
                const new_entry = self.get_entry(key, value, fetched_entry);
                _ = self.primary_store.entries.remove(key);
                self.primary_store.entries.put(key, new_entry) catch unreachable;
            } else if (self.secondary_store.entries.get(key)) |fetched_entry| {
                const new_entry = self.get_entry(key, value, fetched_entry);
                _ = self.secondary_store.entries.remove(key);
                self.primary_store.entries.put(key, new_entry) catch unreachable;
            } else {
                const new_entry = self.get_entry(key, value, null);
                self.primary_store.entries.put(key, new_entry) catch unreachable;
            }
        }
    }
};
