const std = @import("std");
const trait = std.meta.trait;
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
pub fn match(comptime regex: []const u8, str: []const u8) ?MatchResult(regex) {
    return ctregex.match(regex, .{}, str) catch null;
}

/// Wrapper over `(match(regex, str) catch null) != null`.
pub fn isMatch(comptime regex: []const u8, str: []const u8) bool {
    return match(regex, str) != null;
}

/// Return an error if the provided condition is false.
pub fn expect(condition: bool) !void {
    if (!condition) return error.AssertionFailed;
}

/// Return an error if the provided values are inequal.
pub fn expectEq(a: anytype, b: anytype) !void {
    if (a != b) return error.AssertionFailed;
}

/// Return an error if the provided values are equal.
pub fn expectNe(a: anytype, b: anytype) !void {
    if (a == b) return error.AssertionFailed;
}

/// Return an error if the number is outside of the provided bounds.
/// Otherwise, return the number to use in another expression.
pub fn expectRange(num: anytype, lower: anytype, upper: anytype) !@TypeOf(num) {
    if (lower <= num and upper >= num) return num;
    return error.AssertionFailed; // num < lower or num > upper
}

/// Can take an optional, array of optionals, or tuple of optionals.
/// Return an error if any of these optional values are null.
pub fn expectNonNull(values: anytype) !void {
    const T = @TypeOf(values);
    if (comptime trait.isTuple(T)) {
        comptime var i = 0;
        inline while (i < values.len) : (i += 1) {
            if (values[i] == null) return error.AssertionFailed;
        }
    } else if (comptime trait.isIndexable(T)) {
        for (values) |value| {
            if (value == null) return error.AssertionFailed;
        }
    } else if (@typeInfo(T) == .Optional) {
        if (values == null) return error.AssertionFailed;
    } else {
        @compileError("expectNonNull unimplemented for " ++ @typeName(T));
    }
}

/// Takes an optional value and unwraps it, returning an error if the value was null.
pub fn unwrap(value: anytype) !std.meta.Child(@TypeOf(value)) {
    return if (value == null) error.AssertionFailed else value.?;
}
