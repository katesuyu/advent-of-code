const std = @import("std");
const util = @import("util");
const input = @embedFile("2.txt");

const Policy = struct {
    password: []const u8,
    min: u8,
    max: u8,
    char: u8,
};

const policies = comptime blk: {
    @setEvalBranchQuota(input.len * 20);
    var lines = std.mem.tokenize(input, "\n");
    var buf: []const Policy = &[_]Policy{};
    while (lines.next()) |line| {
        const max_start = std.mem.indexOfScalar(u8, line, '-').? + 1;
        const max_end = std.mem.indexOfScalarPos(u8, line, max_start, ' ').?;
        buf = buf ++ [_]Policy{.{
            .password = line[(max_end + 4)..],
            .min = util.parseUint(u8, line[0..(max_start - 1)]) catch unreachable,
            .max = util.parseUint(u8, line[max_start..max_end]) catch unreachable,
            .char = line[max_end + 1],
        }};
    }
    break :blk buf;
};

pub fn main(n: util.Utils) !void {
    var policy_1: usize = 0;
    var policy_2: usize = 0;
    for (policies) |p| {
        const slice: *const [1]u8 = &p.char;
        const count = std.mem.count(u8, p.password, slice);
        const min_eq = p.password[p.min - 1] == p.char;
        const max_eq = p.password[p.max - 1] == p.char;
        if (count >= p.min and count <= p.max)
            policy_1 += 1;
        if (min_eq != max_eq)
            policy_2 += 1;
    }
    try n.out.print("{}\n{}\n", .{policy_1, policy_2});
}
