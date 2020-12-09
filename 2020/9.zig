const std = @import("std");
const util = @import("util");
const input = @embedFile("9.txt");

pub fn main(n: util.Utils) !void {
    var lines = std.mem.tokenize(input, "\n");
    var data_stream = try util.List(u32).initCapacity(n.arena, 26);
    while (data_stream.items.len < 25) {
        const line = try util.unwrap(lines.next());
        const int = try util.parseUint(u32, line);
        data_stream.appendAssumeCapacity(int);
    }

    const weak_sum = blk: while (lines.next()) |line| {
        const sum = try util.parseUint(u32, line);
        const preceding = data_stream.items[(data_stream.items.len - 25)..];
        for (preceding) |first, i| {
            for (preceding) |second, j| {
                if (first != second and first + second == sum) {
                    try data_stream.append(n.arena, sum);
                    continue :blk;
                }
            }
        } else break :blk sum;
    } else return error.BadInput;

    const weak_range = blk: for (data_stream.items) |_, i| {
        var sum: u32 = data_stream.items[i];
        if (sum >= weak_sum)
            continue :blk;
        for (data_stream.items[(i + 1)..]) |num, j| {
            sum += num;
            if (sum > weak_sum)
                continue :blk;
            if (sum == weak_sum)
                break :blk data_stream.items[i..][0..(j + 2)];
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
