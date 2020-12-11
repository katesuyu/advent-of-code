const std = @import("std");
const util = @import("util");
const raw_input = @embedFile("9.txt");

const input = comptime blk: {
    @setEvalBranchQuota(raw_input.len * 20);
    var lines = std.mem.tokenize(raw_input, "\n");
    var buf: []const u32 = &[_]u32{};
    while (lines.next()) |line| {
        buf = buf ++ [_]u32{
            util.parseUint(u32, line) catch break,
        };
    }
    std.debug.assert(buf.len > 25);
    break :blk buf;
};

pub fn main(n: util.Utils) !void {
    const weak_sum = blk: for (input[25..]) |sum, i| {
        const preceding = input[i..][0..25];
        for (preceding) |first| {
            for (preceding) |second| {
                if (first != second and first + second == sum) {
                    continue :blk;
                }
            }
        } else break :blk sum;
    } else return error.BadInput;

    const weak_range = blk: for (input) |_, i| {
        var sum: u32 = input[i];
        if (sum >= weak_sum)
            continue :blk;
        for (input[(i + 1)..]) |num, j| {
            sum += num;
            if (sum > weak_sum)
                continue :blk;
            if (sum == weak_sum)
                break :blk input[i..][0..(j + 2)];
        }
    } else return error.BadInput;

    const weakness = blk: {
        var smallest = weak_range[0];
        var largest = weak_range[0];
        for (weak_range[1..]) |num| {
            if (num < smallest)
                smallest = num;
            if (num > largest)
                largest = num;
        }
        break :blk smallest + largest;
    };

    try n.out.print("{}\n{}\n", .{ weak_sum, weakness });
}
