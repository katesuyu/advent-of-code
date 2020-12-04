const std = @import("std");

pub const Utils = struct {
    arena: *std.mem.Allocator,
    gpa: *std.mem.Allocator,
    out: std.fs.File.Writer,
};

pub const List = std.ArrayListUnmanaged;

pub fn Map(comptime K: type, comptime V: type) type {
    return switch(K) {
        []const u8 => std.StringArrayHashMapUnmanaged(V),
        else => std.AutoArrayHashMapUnmanaged(K, V),
    };
}

pub fn list(comptime T: type) List(T) {
    return List(T){};
}

pub fn map(comptime K: type, comptime V: type) Map(K, V) {
    return Map(K, V){};
}

pub fn parse_u32(str: []const u8) ?u32 {
    return std.fmt.parseUnsigned(u32, str, 10) catch null;
}
