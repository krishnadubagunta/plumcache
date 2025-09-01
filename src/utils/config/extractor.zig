//! Extractor extracts information from toml config file
//!
const std = @import("std");
const ArrayHashMap = std.array_hash_map.ArrayHashMap;
const Allocator = std.mem.Allocator;
const toml = @import("toml");
const CONFIG_FILE_PATH: []const u8 = "./default_config.toml";
const ENV_VAR_FOR_CONFIG: []const u8 = "CONFIG_FILE_PATH";

const PluginConf = struct {
    eviction: ArrayHashMap,
    queue: ArrayHashMap,
};

/// Config object for Plumcache
pub const Config = struct {
    allocator: *Allocator,
    port: []const u8,
    delimiter: []const u8,
    plugins: PluginConf,

    pub fn init(allocator: *Allocator) *Config {
        const _config = Config{ .allocator = allocator };
        // read from file
        return _config;
    }

    fn filepathForConfig(self: *Config) []u8 {
        const config_exists = std.process.hasEnvVar(self.allocator, ENV_VAR_FOR_CONFIG);
        var file_path = CONFIG_FILE_PATH;
        if (config_exists) {
            file_path = std.process.getEnvVarOwned(self.allocator, ENV_VAR_FOR_CONFIG);
        }
        return file_path;
    }

    fn readFromFile(self: *Config) void {
        const file_path = self.filepathForConfig();
        defer self.allocator.free(file_path);

        // var parser = toml.Parser(self.*).init(self.allocator);
    }
};
