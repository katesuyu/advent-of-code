const std = @import("std");
const util = @import("util");
const input = @embedFile("3.txt");

const width = std.mem.indexOfScalar(u8, input, '\n').?;
const height = input.len / (width + 1);

fn count(right: usize, down: usize) usize {
    var x = right;
    var y = down;
    var i: usize = 0;
    while (y < height) : ({
        y += down;
        x += right;
        x %= width;
    }) {
        if (input[y * (width + 1) + x] == '#') i += 1;
    }
    return i;
}

pub fn main(n: util.Utils) !void {
    const r1d1 = count(1, 1);
    const r3d1 = count(3, 1);
    const r5d1 = count(5, 1);
    const r7d1 = count(7, 1);
    const r1d2 = count(1, 2);

    try n.out.print("{}\n{}\n", .{r3d1, r1d1 * r3d1 * r5d1 * r7d1 * r1d2});
}
