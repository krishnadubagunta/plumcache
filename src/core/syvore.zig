//! SyvoreStore is the data structure that is used to store the data in the SyvoreDB.
//! It is a key-value store that is used to store the data in the SyvoreDB.

const std = @import("std");
const entry = @import("entry.zig");
const atom = @import("atom.zig");

const Store = struct {
    allocator: std.mem.Allocator,
    entries: std.StringHashMap(entry.Entry),

    pub fn init(allocator: std.mem.Allocator) Store {
        return Store{
            .allocator = allocator,
            .entries = std.StringHashMap(entry.Entry).init(allocator),
        };
    }

    pub fn deinit(self: *Store) void {
        self.entries.deinit();
    }
};

pub const SyvoreStore = struct {
    primary_store: Store,
    secondary_store: Store,

    pub fn init(allocator: std.mem.Allocator) SyvoreStore {
        return SyvoreStore{
            .primary_store = Store.init(allocator),
            .secondary_store = Store.init(allocator),
        };
    }

    pub fn deinit(self: *SyvoreStore) void {
        self.primary_store.deinit();
        self.secondary_store.deinit();
    }

    pub fn set(self: *SyvoreStore, key: []const u8, value: []const u8) !void {
        if (std.mem.indexOf(u8, key, ":") != null) {
            // If : exists, then it's a trie. Now figure out if the index key exists in the entries of primary store first.
            // If it doesn't, check secondary store and upgrade it to primary store if it exists.
            // If it doesn't exist in secondary store, create a new trie and set the value in the primary store.
        } else {
            // Now check if the key exists in the entries of primary store.
            // If it doesn't, check secondary store and upgrade it to primary store if it exists.
            // If it doesn't exist in secondary store, create a new entry and set the value in the primary store.

            if (self.primary_store.entries.get(key)) |fetched_entry| {
                const pure_value = atom.PureSyvoreAtom.init(key, value, atom.AtomOptions{ .access_count = fetched_entry.value.atom.access_count + 1, .last_accessed = std.time.milliTimestamp() });
                const new_entry_value = entry.EntryValue{ .atom = pure_value };
                const new_entry = entry.Entry{ .key = key, .value = new_entry_value };
                _ = self.primary_store.entries.remove(key);
                self.primary_store.entries.put(key, new_entry) catch unreachable;
            } else if (self.secondary_store.entries.get(key)) |fetched_entry| {
                const pure_value = atom.PureSyvoreAtom.init(key, value, atom.AtomOptions{ .access_count = fetched_entry.value.atom.access_count + 1, .last_accessed = std.time.milliTimestamp() });
                const new_entry_value = entry.EntryValue{ .atom = pure_value };
                const new_entry = entry.Entry{ .key = key, .value = new_entry_value };
                _ = self.secondary_store.entries.remove(key);
                self.primary_store.entries.put(key, new_entry) catch unreachable;
            } else {
                const pure_value = atom.PureSyvoreAtom.init(key, value, null);
                const new_entry_value = entry.EntryValue{ .atom = pure_value };
                const new_entry = entry.Entry{ .key = key, .value = new_entry_value };
                self.primary_store.entries.put(key, new_entry) catch unreachable;
            }
        }
    }
};
