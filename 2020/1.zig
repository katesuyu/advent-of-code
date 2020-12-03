const std = @import("std");
const util = @import("util");
const input = @embedFile("1.txt");

pub fn main(n: util.Utils) !void {
    var lines = std.mem.tokenize(input, "\n");
    var expenses = util.list(u32);
    while (lines.next()) |line| {
        const entry = try expenses.addOne(n.arena);
        entry.* = try std.fmt.parseUnsigned(u32, line, 10);
    }
    var part_1: ?u32 = null;
    var part_2: ?u32 = null;
    for (expenses.items) |a| {
        for (expenses.items) |b| {
            const sum = a + b;
            if (sum == 2020)
                part_1 = a * b;
            for (expenses.items) |c| {
                if (sum + c == 2020)
                    part_2 = a * b * c;
            }
        }
    }
    if (part_1 == null or part_2 == null)
        return error.Unexpected;
    try n.out.print("{}\n{}\n", .{part_1.?, part_2.?});
}
