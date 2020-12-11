const std = @import("std");
const util = @import("util");
const input = comptime util.gridRows(@embedFile("3.txt"));

pub fn main(n: util.Utils) !void {
    const slopes = .{
        .{ 1, 1 },
        .{ 3, 1 },
        .{ 5, 1 },
        .{ 7, 1 },
        .{ 1, 2 },
    };
    var counts = [_]usize{0} ** 5;
    var x = [_]usize{0} ** 5;
    for (input) |row, y| {
        inline for (slopes) |slope, i| {
            if (y % slope[1] == 0) {
                if (row[x[i]] == '#')
                    counts[i] += 1;
                x[i] += slope[0];
                x[i] %= row.len;
            }
        }
    }
    var product = counts[0];
    for (counts[1..]) |num|
        product *= num;
    try n.out.print("{}\n{}\n", .{ counts[1], product });
}
