//! This module provides functionality for loading and parsing configuration files.
//!
//! It extracts settings from TOML format configuration files, supporting both default
//! configuration paths and environment variable overrides. The configuration includes
//! settings for the server (like port number and delimiter) and plugin configuration.
//!
const std = @import("std");
const ArrayHashMap = std.array_hash_map.ArrayHashMap;
const Allocator = std.mem.Allocator;
const toml = @import("toml");
/// Default path to the configuration file if not specified by environment variable
const CONFIG_FILE_PATH: []const u8 = "./default_config.toml";
/// Environment variable name that can be used to override the default config file path
const ENV_VAR_FOR_CONFIG: []const u8 = "CONFIG_FILE_PATH";

/// `PluginConf` holds configuration settings for different types of plugins.
///
/// It contains separate configuration maps for each plugin category,
/// allowing for flexible plugin configuration.
const PluginConf = struct {
    /// Configuration for eviction policy plugins
    eviction: ArrayHashMap,
    /// Configuration for queue management plugins
    queue: ArrayHashMap,
};

/// `Config` is the main configuration object for PlumCache.
///
/// It contains all settings needed to run the PlumCache server,
/// including network settings, parsing options, and plugin configurations.
pub const Config = struct {
    /// Memory allocator used for dynamic allocations within configuration
    allocator: *Allocator,
    /// The port number the server will listen on, stored as a string
    port: []const u8,
    /// The delimiter used for tokenizing namespaced keys
    delimiter: []const u8,
    /// Configuration for various plugins grouped by category
    plugins: PluginConf,

    /// Initializes a new `Config` instance with the provided allocator.
    ///
    /// This creates the basic configuration structure but does not yet
    /// load values from the configuration file.
    ///
    /// Parameters:
    ///   - `allocator`: Memory allocator to use for configuration-related allocations.
    ///
    /// Returns:
    ///   - A pointer to the newly created `Config` instance.
    pub fn init(allocator: *Allocator) *Config {
        const _config = Config{ .allocator = allocator };
        // read from file
        return _config;
    }

    /// Determines the path to the configuration file to use.
    ///
    /// It first checks if an environment variable (specified by `ENV_VAR_FOR_CONFIG`)
    /// is set. If so, it uses that path. Otherwise, it falls back to the default
    /// configuration path (`CONFIG_FILE_PATH`).
    ///
    /// Returns:
    ///   - A slice of `u8` representing the path to the configuration file.
    ///     The caller is responsible for freeing this memory.
    fn filepathForConfig(self: *Config) []u8 {
        const config_exists = std.process.hasEnvVar(self.allocator, ENV_VAR_FOR_CONFIG);
        var file_path = CONFIG_FILE_PATH;
        if (config_exists) {
            file_path = std.process.getEnvVarOwned(self.allocator, ENV_VAR_FOR_CONFIG);
        }
        return file_path;
    }

    /// Reads and parses the configuration from the TOML file.
    ///
    /// This method:
    /// 1. Determines the path to the configuration file
    /// 2. Initializes a TOML parser
    /// 3. Parses the file and populates the configuration object
    /// 4. Logs the result for debugging purposes
    ///
    /// The memory for the file path is automatically freed when this function returns.
    fn readFromFile(self: *Config) void {
        const file_path = self.filepathForConfig();
        defer self.allocator.free(file_path);

        var parser = toml.Parser(self.*).init(self.allocator);
        const result = parser.parseFile(file_path);
        std.log.debug("Result: {}", .{result});
    }
};
