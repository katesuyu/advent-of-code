const std = @import("std");
const ctregex = @import("ctregex");

/// A collection of utilities that are likely to be used on a fairly common
/// basis and would therefore cause repetitive, avoidable boilerplate.
pub const Utils = struct {
    arena: *std.mem.Allocator,
    gpa: *std.mem.Allocator,
    out: std.fs.File.Writer,
};

/// An alias for ArrayListUnmanaged because unmanaged is the best default.
pub const List = std.ArrayListUnmanaged;

/// Automatically chooses StringArrayHashMapUnmanaged(V) if K is []const u8,
/// otherwise chooses AutoArrayHashMapUnmanaged(K, V). Saves a lot of typing.
pub fn Map(comptime K: type, comptime V: type) type {
    return switch(K) {
        []const u8 => std.StringArrayHashMapUnmanaged(V),
        else => std.AutoArrayHashMapUnmanaged(K, V),
    };
}

/// Convenience constructor for List(T){}.
pub fn list(comptime T: type) List(T) {
    return List(T){};
}

/// Convenience constructor for Map(K, V){}.
pub fn map(comptime K: type, comptime V: type) Map(K, V) {
    return Map(K, V){};
}

/// Convenience wrapper over parseUnsigned for u32 radix 10.
pub fn parse_u32(str: []const u8) !u32 {
    return std.fmt.parseUnsigned(u32, str, 10);
}

/// Wrapper over ctregex.MatchResult that compile errors instead of silently
/// returning `void` when the regex fails to parse.
pub fn MatchResult(comptime regex: []const u8) type {
    const T = ctregex.MatchResult(regex, .{});
    if (T == void)
        @compileError("Failed to parse regex: " ++ regex);
    return T;
}

/// Wrapper over ctregex.match that is UTF-8 always and compile errors if the
/// regex is invalid instead of silently returning `void`.
pub fn match(comptime regex: []const u8, str: []const u8) !?MatchResult(regex) {
    return ctregex.match(regex, .{}, str);
}

/// Wrapper over `(match(regex, str) catch null) != null`.
pub fn isMatch(comptime regex: []const u8, str: []const u8) bool {
    return (match(regex, str) catch null) != null;
}
