//! PlumDB
//! A simple key-value store with a trie-based data structure.
//!
//! This is a work in progress and is not yet ready for production.
//!
//! The main goal of this project is to learn about the Zig programming language and how to use it to build a simple key-value store.
//!
//! The data structure is a trie-based data structure.
//!
pub const plum = @import("core/plum.zig");
pub const commands = @import("utils/commands.zig");
pub const handlers = @import("handlers/handler.zig");
pub const tokenize = @import("utils/tokenize.zig");
