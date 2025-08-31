//! Entry is the data structure that is used to store the data in the Plum.
//!
//! It is a key-value pair.
//!
//! The key is the path to the data in the Plum.
//!
//! The value can be an atom or a trie.
//!

const std = @import("std");
const atom = @import("atom.zig");
const trie = @import("trie.zig");

pub const Entry = struct {
    key: []const u8,
    value: EntryValue,
};

pub const EntryValue = union(enum) {
    atom: atom.PurePlumAtom,
    trie: trie.PlumTrie,
};
