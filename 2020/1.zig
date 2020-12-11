const std = @import("std");
const util = @import("util");
const input = @embedFile("1.txt");

const expenses = comptime blk: {
    @setEvalBranchQuota(input.len * 20);
    var lines = std.mem.tokenize(input, "\n");
    var buf: []const u32 = &[_]u32{};
    while (lines.next()) |line|
        buf = buf ++ [_]u32{util.parseUint(u32, line) catch unreachable};
    break :blk buf;
};

pub fn main(n: util.Utils) !void {
    var part_1: ?u32 = null;
    var part_2: ?u32 = null;
    for (expenses) |a| {
        for (expenses) |b| {
            const sum = a + b;
            if (sum == 2020)
                part_1 = a * b;
            for (expenses) |c| {
                if (sum + c == 2020)
                    part_2 = a * b * c;
            }
        }
    }
    try util.expectNonNull(.{part_1, part_2});
    try n.out.print("{}\n{}\n", .{part_1.?, part_2.?});
}
