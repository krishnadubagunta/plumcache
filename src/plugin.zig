//! This module defines the plugin system for PlumCache.
//!
//! The plugin system enables extensibility through hooks that can intercept and modify
//! database operations at various points in their execution lifecycle. This allows
//! for custom functionality such as validation, transformation, logging, and more,
//! without modifying the core database code.
//!
//! The main components are:
//! - `HookType`: An enumeration of the available interception points
//! - `Plugin`: A structure that defines a plugin's metadata and execution function

/// `HookType` defines the points in the database operation lifecycle where plugins can intercept.
///
/// Each hook type represents a specific moment during data operations:
/// - `Before*` hooks run before an operation is performed, allowing for validation or modification
/// - `After*` hooks run after an operation completes, enabling post-processing or side effects
///
/// This enum-based approach allows for type-safe hook registration and dispatch.
pub const HookType = enum {
    /// Triggered before retrieving a key's value
    BeforeGet,
    /// Triggered before saving a key-value pair
    BeforeSave,
    /// Triggered before deleting a key
    BeforeDelete,
    /// Triggered after retrieving a key's value
    AfterGet,
    /// Triggered after saving a key-value pair
    AfterSave,
    /// Triggered after deleting a key
    AfterDelete,
};

/// `Plugin` represents an extension module that can hook into the database operations.
///
/// Each plugin has:
/// - A name for identification
/// - A hook type specifying when it should be executed
/// - A function that will be called when the hook triggers
///
/// The plugin's run function receives the operation's key and value as parameters,
/// allowing it to inspect or modify the data being processed.
pub const Plugin = struct {
    /// Unique identifier for the plugin
    name: []const u8,
    /// The point in execution where this plugin should be triggered
    hook: HookType,
    /// Function to call when the hook is triggered.
    ///
    /// Parameters:
    ///   - `key`: The key involved in the database operation.
    ///   - `value`: The value involved in the database operation.
    ///
    /// Returns:
    ///   - `void`. This function does not return a value.
    run: *const fn (key: []u8, value: []u8) void,
};
