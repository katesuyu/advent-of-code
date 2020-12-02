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
    const part_1 = blk: {
        for (expenses.items) |a|
            for (expenses.items) |b|
                if (a + b == 2020)
                    break :blk a * b;
        return error.Unexpected;
    };
    const part_2 = blk: {
        for (expenses.items) |a|
            for (expenses.items) |b|
                for (expenses.items) |c|
                    if (a + b + c == 2020)
                        break :blk a * b * c;
        return error.Unexpected;
    };
    try n.out.print("{}\n{}\n", .{part_1, part_2});
}
