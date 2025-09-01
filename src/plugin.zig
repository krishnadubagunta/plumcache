pub const HookType = enum { BeforeGet, BeforeSave, BeforeDelete, AfterGet, AfterSave, AfterDelete };

pub const Plugin = struct { name: []const u8, hook: HookType, run: *const fn (key: []u8, value: []u8) void };
