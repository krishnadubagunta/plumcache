//! This file contains the definition of the Plugin struct and the HookType enum.

/// This enum represents the different types of hooks that can be registered for plugins.
pub const HookType = enum { BeforeGet, BeforeSave, BeforeDelete, AfterGet, AfterSave, AfterDelete };

/// This struct represents a plugin that can be registered with the database.
pub const Plugin = struct { name: []const u8, hook: HookType, run: *const fn (key: []u8, value: []u8) void };
