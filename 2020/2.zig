const std = @import("std");
const util = @import("util");
const input = @embedFile("2.txt");

pub fn main(n: util.Utils) !void {
    var lines = std.mem.tokenize(input, "\n");
    var policy_1: usize = 0;
    var policy_2: usize = 0;
    while (lines.next()) |line| {
        var min_end: usize = 0;
        while (line[min_end] >= '0' and line[min_end] <= '9') : (min_end += 1) {}
        const min = try std.fmt.parseUnsigned(usize, line[0..min_end], 10);

        const max_start = min_end + 1;
        var max_end = max_start;
        while (line[max_end] >= '0' and line[max_end] <= '9') : (max_end += 1) {}
        const max = try std.fmt.parseUnsigned(usize, line[max_start..max_end], 10);

        const char = line[max_end + 1];
        const password = line[max_end + 4..];

        var occurrences: usize = 0;
        for (password) |c| {
            if (c == char)
                occurrences += 1;
        }

        if (occurrences >= min and occurrences <= max)
            policy_1 += 1;

        if ((password[min - 1] == char) != (password[max - 1] == char))
            policy_2 += 1;
    }
    try n.out.print("{}\n{}\n", .{policy_1, policy_2});
}
