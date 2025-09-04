//! Orchestrator loads, initiates, and registers all the plugins available.
//!
//! Initializing the Orchestrator facilitates the following:
//!   1. Download of all the plugins listed in config file from github
//!   2. Loads all the plugins
//!   3. Registers the subscribers
const std = @import("std");
const plugins = @import("./plugin.zig");

/// This struct represents the orchestrator that manages the plugins.
pub const Orchestrator = struct {
    allocator: std.mem.Allocator,
    plugins: std.array_list.Managed(*plugins.Plugin),

    pub fn init(allocator: std.mem.Allocator) void {
        _ = Orchestrator{ .allocator = allocator, .plugins = std.array_list.Managed(*plugins.Plugin).init(allocator) };

        // load plugins from toml.
        // _orchestrator.loadPlugins();
    }

    // fn loadPlugins(self: *Orchestrator) void {}
};
