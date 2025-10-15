//! This module defines the Orchestrator, a central component in PlumCache
//! responsible for managing the entire lifecycle of plugins.
//!
//! The Orchestrator acts as an extensibility manager, enabling dynamic discovery,
//! loading, initialization, and coordination of various plugins. It serves
//! as the bridge between the core database functionality and external
//! extensions, allowing PlumCache to be customized and expanded without
//! altering its core codebase.
//!
//! Key responsibilities include:
//! - **Plugin Discovery**: Identifying available plugins based on configuration.
//! - **Plugin Loading**: Loading plugin binaries or modules into memory.
//! - **Plugin Initialization**: Setting up plugins and preparing them for execution.
//! - **Hook Management**: Registering plugin functions to specific hooks within
//!   the PlumCache operation lifecycle (e.g., `BeforeSave`, `AfterGet`).
//! - **Dependency Resolution**: (Future) Managing inter-plugin dependencies.
//! - **Execution Order**: (Future) Ensuring plugins run in a defined order.
//!
//! By centralizing plugin management, the Orchestrator ensures a robust and
//! flexible architecture for extending PlumCache's capabilities.
const std = @import("std");
const extractor = @import("utils/config/extractor.zig");
const plumplugin = @import("plumplugin");

/// `Orchestrator` is the central component responsible for managing the plugin ecosystem.
///
/// It handles plugin discovery, loading, initialization, and hooks management,
/// creating a bridge between the core functionality and extension points.
pub const Orchestrator = struct {
    /// Memory allocator used for dynamic allocations within the orchestrator
    allocator: std.mem.Allocator,
    /// Managed list of active plugins that have been loaded into the system
    plugins: std.ArrayListUnmanaged(*const plumplugin.plugin.Plugin),

    /// Initializes a new `Orchestrator` instance with the provided allocator.
    ///
    /// This function sets up the basic orchestrator structure but doesn't yet
    /// load or initialize plugins. The plugin loading process would typically be
    /// driven by configuration settings (commented out in the current implementation).
    ///
    /// Parameters:
    ///   - `allocator`: Memory allocator to use for orchestrator-related allocations.
    ///
    /// Returns:
    ///   - A new `Orchestrator` instance.
    ///
    /// Note: The current implementation initializes the orchestrator but doesn't
    /// retain a reference to it, which would need to be addressed for actual use.
    pub fn init(allocator: std.mem.Allocator) !Orchestrator {
        const configurator = extractor.Configurator.init(allocator);
        const config = try configurator.readFromFile();
        const pluginsLen = config.plugins.eviction.srcSet.len + config.plugins.eviction.srcSet.len;
        const _orchestrator = Orchestrator{
            .allocator = allocator,
            .plugins = std.ArrayListUnmanaged(*const plumplugin.plugin.Plugin).initCapacity(allocator, pluginsLen) catch unreachable,
        };

        return _orchestrator;
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
    ///
    /// Parameters:
    ///   - `self`: A pointer to the `Orchestrator` instance.
    pub fn loadPlugins(self: *Orchestrator) !void {
        // TODO: Implement plugin loading logic here.
        if (@inComptime()) {
            @compileError("Error: Running in comptime");
        }
        const configurator = extractor.Configurator.init(self.allocator);
        const config = try configurator.readFromFile();
        if (config.plugins.eviction.srcSet.len > 0) {
            for (config.plugins.eviction.srcSet) |src| {
                std.debug.print("Plugin Eviction: {s}", .{src});
                const plugin = plumplugin.loadPlugin(src) catch |err| {
                    std.debug.print("Error loading plugin: {}\n", .{err});
                    return err;
                };
                try self.plugins.append(self.allocator, plugin);
            }
        }

        if (config.plugins.queue.srcSet.len > 0) {
            for (config.plugins.queue.srcSet) |src| {
                std.debug.print("Plugin Queue: {s}", .{src});
                const plugin = plumplugin.loadPlugin(src) catch |err| {
                    std.debug.print("Error loading plugin: {}\n", .{err});
                    return err;
                };
                try self.plugins.append(self.allocator, plugin);
            }
        }
    }
};
