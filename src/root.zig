//! PlumCache
//! A high-performance, plugin-managed in-memory key-value store with a trie-based architecture.
//!
//! PlumCache is designed as a flexible, extensible in-memory data store that leverages a trie
//! (prefix tree) data structure for efficient key operations. The system features a plugin
//! architecture that allows for dynamic extension of functionality through modular components.
//!
//! ## Architecture Overview
//!
//! PlumCache is built around several core components:
//! - **Core Engine**: The main trie-based storage engine that handles data operations
//! - **Plugin System**: Extensible architecture for adding custom functionality
//! - **Command Processing**: Unified command interface with parsing and validation
//! - **Handler Layer**: Request/response handling with plugin integration
//! - **Orchestrator**: Coordinates between components and manages plugin lifecycle
//!
//! ## Key Features
//!
//! - **Trie-Based Storage**: Efficient prefix-based key operations with O(m) complexity
//!   where m is the key length, enabling fast lookups, insertions, and prefix queries
//! - **Plugin Architecture**: Dynamic loading and management of plugins to extend
//!   database functionality without core modifications
//! - **In-Memory Performance**: Optimized for speed with all data kept in memory
//! - **Command Tokenization**: Robust parsing system for command processing
//! - **Modular Design**: Clean separation of concerns for maintainability
//!
//! ## Module Structure
//!
//! ### Core Components
//! - `plum`: Main storage engine implementing the trie data structure
//! - `orchestration`: Plugin lifecycle management and component coordination
//!
//! ### Utilities
//! - `commands`: Command definitions and validation logic
//! - `tokenize`: Command parsing and tokenization utilities
//!
//! ### Interface Layer
//! - `handlers`: Request processing and response generation
//!
//! ## Development Status
//!
//! This is an active development project focused on creating a production-ready
//! in-memory database with plugin capabilities. Current development priorities
//! include plugin API stabilization, performance optimization, and comprehensive
//! testing coverage.
//!
//! ## Plugin Development
//!
//! Plugins can extend PlumCache functionality by implementing the plugin interface.
//! The orchestrator manages plugin lifecycle, dependency resolution, and
//! ensures proper integration with the core engine.
//!
//! ## Usage Examples
//!
//! ### 1. Start the PlumCache Server
//! Build and run the server binary (default port: `7379`):
//!
//! ```bash
//! zig build run
//! ```
//!
//! The server will listen on `127.0.0.1:7379`.
//!
//! ### 2. Connect with Netcat
//! You can interact with PlumCache directly using `netcat`:
//!
//! ```bash
//! nc 127.0.0.1 7379
//! ```
//!
//! Once connected, you can issue commands line by line:
//!
//! ```text
//! PING
//! +PONG
//!
//! SET user:1001:name Alice
//! +OK
//!
//! GET user:1001:name
//! $5
//! Alice
//!
//! SET session:token abc123
//! +OK
//!
//! GET session:token
//! $6
//! abc123
//! ```
//!
//! ### 3. Using Plugins (Example: TTL)
//! If the TTL plugin is registered, you can set keys with expiration:
//!
//! ```text
//! SET cache:item1 value EX 5
//! +OK
//!
//! GET cache:item1
//! $5
//! value
//!
//! # after 5 seconds
//! GET cache:item1
//! $-1
//! ```
//!
//! ### 4. Prefix / Trie Features
//! PlumCache’s trie-based storage allows efficient prefix operations.
//! Example command (if supported by installed plugin):
//!
//! ```text
//! KEYS user:*
//! *1
//! user:1001:name
//! ```
//!
//! ### 5. Exit
//! Simply close the netcat session with `Ctrl+D` or `Ctrl+C`.
pub const store = @import("core/store.zig");
pub const commands = @import("utils/commands.zig");
pub const handlers = @import("handlers/handler.zig");
pub const tokenize = @import("utils/tokenize.zig");
pub const orchestration = @import("orchestrator.zig");
