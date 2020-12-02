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
