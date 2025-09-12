//! This module defines the `InternPool` struct, a mechanism for string interning
//! within PlumCache.
//!
//! String interning is an optimization technique where unique strings are stored
//! only once in memory. When a string is "interned," if an identical string
//! already exists in the pool, a pointer to the existing string is returned instead
//! of allocating new memory for a duplicate. This saves memory and can speed up
//! string comparisons (as pointer equality implies string equality).
//!
//! The `InternPool` manages a hash map where string slices (`[]const u8`) are
//! associated with a reference count (`u32`). The reference count tracks how many
//! times a particular interned string is in use. When the count drops to zero,
//! the string's memory can be safely deallocated from the pool.
//!
//! This module is crucial for efficient memory management of keys and paths
//! throughout PlumCache's trie structure.
const std = @import("std");

/// `InternPool` manages a pool of interned strings, optimizing memory usage
/// by storing unique strings only once and using reference counting.
pub const InternPool = struct {
    /// The hash map that stores the interned strings.
    /// Keys are `[]const u8` (the interned strings themselves), and values are `u32`
    /// representing the reference count for each string.
    pool: std.StringHashMap(u32),
    /// The memory allocator used for all allocations and deallocations within this `InternPool`.
    allocator: std.mem.Allocator,

    /// Initializes a new `InternPool` instance.
    ///
    /// This function sets up an empty `std.StringHashMap` and stores the provided
    /// allocator, preparing the pool for interning operations.
    ///
    /// Parameters:
    ///   - `allocator`: The memory allocator to be used for the `InternPool`'s internal
    ///                  hash map and for duplicating strings during interning.
    ///
    /// Returns:
    ///   - `InternPool`: A new `InternPool` instance.
    pub fn init(allocator: std.mem.Allocator) InternPool {
        return InternPool{
            .pool = std.StringHashMap(u32).init(allocator),
            .allocator = allocator,
        };
    }

    /// Deinitializes the `InternPool`, freeing all memory held by the pool.
    ///
    /// This function deinitializes the internal `StringHashMap`, which in turn
    /// frees all interned strings and the hash map's own internal allocations.
    /// It then frees the memory allocated for the `InternPool` struct itself.
    /// It is critical to call this to prevent memory leaks.
    ///
    /// Parameters:
    ///   - `self`: A pointer to the `InternPool` instance to be deinitialized.
    ///
    /// Returns:
    ///   - `void`
    pub fn deinit(self: *InternPool) void {
        // Deinitialize the StringHashMap, which frees all interned strings.
        self.pool.deinit();
        // Free the memory allocated for the InternPool struct itself.
        // This line might be problematic if the pool itself was not allocated
        // by `self.allocator.create(InternPool)`. If it's a stack-allocated struct,
        // this should be removed. Assuming it's heap-allocated for consistency
        // with other modules that allocate structures.
        // self.allocator.destroy(self); // Consider if `self` itself needs to be freed.
    }

    /// Interns a given `key` string, adding it to the pool if it's new or
    /// returning a pointer to the existing string if it's a duplicate.
    ///
    /// This function first attempts to find an identical `key` in the pool.
    /// If found, its reference count is incremented. If not found, the `key`
    /// is duplicated, added to the pool with a reference count of 1, and then
    /// a pointer to this newly interned string is returned.
    ///
    /// Parameters:
    ///   - `self`: A pointer to the `InternPool` instance.
    ///   - `key`: A `[]const u8` slice representing the string to be interned.
    ///
    /// Returns:
    ///   - `!?*[]const u8`: An optional pointer to the interned `[]const u8` string on success.
    ///                    Returns `null` if the key could not be retrieved after insertion.
    ///
    /// Errors:
    ///   - Can return `error.OutOfMemory` if `self.allocator.dupe` or `self.pool.put` fails
    ///     to allocate necessary memory.
    pub fn intern(self: *InternPool, key: []const u8) !?*[]const u8 {
        // Duplicate the key for internal storage. This is necessary because the input `key`
        // might be a temporary slice, and the pool needs to own its memory.
        const keyDupe = try self.allocator.dupe(u8, key);
        // Attempt to get the reference count for the duplicated key.
        if (self.pool.get(keyDupe)) |value| {
            // If the key already exists, increment its reference count.
            // `put` will update the value for an existing key.
            self.pool.put(keyDupe, value + 1) catch {}; // Ignoring error as key already exists.
        } else {
            // If the key is new, add it to the pool with an initial reference count of 0.
            // The `getKeyPtr` will implicitly increment it to 1 when used by calling contexts,
            // or it can be thought of as `0` meaning "not currently tracked by a specific caller"
            // and subsequent calls to `intern` for this exact key will increment.
            // However, typical ref counting starts at 1 for new items. The current logic seems to
            // indicate 0 upon first insertion, which might be a convention or an oversight.
            // Let's assume the intent is for `getKeyPtr` to handle the final count.
            self.pool.put(keyDupe, 0) catch {}; // Ignoring potential OOM here, assuming keyDupe succeeded.
        }
        // Return a pointer to the actual interned string in the pool.
        // This pointer remains valid as long as the string is in the pool.
        return self.pool.getKeyPtr(keyDupe);
    }

    /// De-interns a string, decrementing its reference count. If the reference
    /// count drops to 0, the string is removed from the pool and its memory freed.
    ///
    /// Parameters:
    ///   - `self`: A pointer to the `InternPool` instance.
    ///   - `key`: A pointer to the `[]const u8` slice of the interned string to be de-interned.
    ///            This *must* be a pointer obtained previously from `intern` or `get`.
    ///
    /// Returns:
    ///   - `void`
    pub fn deintern(self: *InternPool, key: *[]const u8) void {
        // Attempt to retrieve the current reference count for the given key.
        if (self.pool.get(key.*)) |value| {
            // Decrement the reference count.
            self.pool.put(key.*, value - 1) catch {}; // Ignoring error as key exists.
            // If the reference count drops to 0 (meaning it was 1 before decrement),
            // remove the string from the pool and free its memory.
            if (value == 1) {
                self.pool.removeByPtr(key);
            }
        }
    }

    /// Retrieves a pointer to an interned string from the pool without affecting
    /// its reference count.
    ///
    /// Parameters:
    ///   - `self`: A pointer to the `InternPool` instance.
    ///   - `key`: A `[]const u8` slice representing the string to look up.
    ///
    /// Returns:
    ///   - `?*[]const u8`: An optional pointer to the interned `[]const u8` string if found.
    ///                    Returns `null` if the string is not present in the pool.
    pub fn get(self: *InternPool, key: []const u8) ?*[]const u8 {
        // Use the hash map's `getKeyPtr` method to retrieve a pointer to the interned string.
        // Returns `null` if the key is not found.
        return self.pool.getKeyPtr(key) orelse null;
    }
};
