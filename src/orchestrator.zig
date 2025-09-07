//! This module defines the Orchestrator, responsible for plugin management in PlumCache.
//!
//! The Orchestrator acts as a central coordinator for the plugin system, handling the
//! entire plugin lifecycle from discovery to registration. It serves as an intermediary
//! between the core database and its extensibility mechanisms.
//!
//! Initializing the Orchestrator facilitates the following:
//!   1. Download of all the plugins listed in config file from github
//!   2. Loads all the plugins into memory and initializes them
//!   3. Registers the subscribers to various hooks in the system
//!   4. Manages plugin dependencies and execution order
const std = @import("std");
const plugins = @import("./plugin.zig");

/// `Orchestrator` is the central component responsible for managing the plugin ecosystem.
///
/// It handles plugin discovery, loading, initialization, and hooks management,
/// creating a bridge between the core functionality and extension points.
pub const Orchestrator = struct {
    /// Memory allocator used for dynamic allocations within the orchestrator
    allocator: std.mem.Allocator,
    /// Managed list of active plugins that have been loaded into the system
    plugins: std.array_list.Managed(*plugins.Plugin),

    /// Initializes a new `Orchestrator` instance with the provided allocator.
    ///
    /// This function sets up the basic orchestrator structure but doesn't yet
    /// load or initialize plugins. The plugin loading process would typically be
    /// driven by configuration settings (commented out in the current implementation).
    ///
    /// Parameters:
    ///   - `allocator`: Memory allocator to use for orchestrator-related allocations.
    ///
    /// Note: The current implementation initializes the orchestrator but doesn't
    /// retain a reference to it, which would need to be addressed for actual use.
    pub fn init(allocator: std.mem.Allocator) void {
        _ = Orchestrator{ .allocator = allocator, .plugins = std.array_list.Managed(*plugins.Plugin).init(allocator) };

        // load plugins from toml.
        // _orchestrator.loadPlugins();
    }

    /// Loads plugins based on configuration settings.
    ///
    /// This would typically:
    /// 1. Read plugin information from configuration
    /// 2. Download or locate plugin binary files
    /// 3. Load them into memory
    /// 4. Initialize each plugin
    /// 5. Register their hooks with the appropriate systems
    ///
    /// Currently this function is stubbed out for future implementation.
    fn loadPlugins(_: *Orchestrator) void {
        // TODO: Implement plugin loading logic here.
        @compileError("Todo! Implement plugin loading logic here.");
    }
};
