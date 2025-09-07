//! This module defines the `Entry` and `EntryValue` structures, which are used to represent
//! the top-level items stored directly within the `PlumStore`.
//!
//! An `Entry` is a wrapper that pairs a key with a value. The value itself is represented
//! by the `EntryValue` union, which can hold different types of data structures, specifically
//! either a `PurePlumAtom` for simple key-value data or a `PlumTrie` for namespaced,
//! hierarchical data. This allows the `PlumStore` to manage both simple and complex
//! data structures under a single, unified interface.

const std = @import("std");
const atom = @import("atom.zig");
const trie = @import("trie.zig");

/// `Entry` represents a single key-value pair stored in the `PlumStore`.
/// It encapsulates the top-level keys and their corresponding data structures.
pub const Entry = struct {
    /// The primary key for this entry. For a trie, this is the namespace.
    key: []const u8,
    /// The value associated with the key, which can be an atom or a trie.
    value: EntryValue,
};

/// `EntryValue` is a tagged union that represents the different types of values an `Entry` can hold.
/// This allows the `PlumStore` to store different kinds of data structures in its main hash map.
pub const EntryValue = union(enum) {
    /// A `PurePlumAtom` for storing a simple key-value pair with metadata.
    atom: atom.PurePlumAtom,
    /// A `PlumTrie` for storing hierarchical data under a common namespace.
    trie: trie.PlumTrie,
};
