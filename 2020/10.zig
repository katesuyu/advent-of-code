const std = @import("std");
const util = @import("util");
const input = @embedFile("10.txt");

const Adapter = struct {
    joltage: u16,
    connections: [3]u16 = [_]u16{0} ** 3,
    arrangements: u64 = 0,
};

const joltages = comptime blk: {
    @setEvalBranchQuota(input.len * 20);
    var lines = std.mem.tokenize(input, "\n");
    var buf: []const u16 = &[_]u16{};
    while (lines.next()) |line| {
        buf = buf ++ [_]u16{
            util.parseUint(u16, line) catch unreachable,
        };
    }
    var sorted = buf[0..buf.len].*;
    std.sort.sort(u16, &sorted, {}, std.sort.asc(u16));
    break :blk &sorted;
};

pub fn main(n: util.Utils) !void {
    var adapters = comptime blk: {
        var buf: [joltages.len + 2]Adapter = undefined;
        for (joltages) |joltage, i|
            buf[i + 1] = .{ .joltage = joltage };
        buf[0] = .{ .joltage = 0 };
        buf[buf.len - 1] = .{
            .joltage = joltages[joltages.len - 1] + 3,
            .arrangements = 1,
        };
        break :blk buf;
    };

    var diff_1: usize = 0;
    var diff_3: usize = 0;
    for (adapters) |*adapter, i| {
        var j: u16 = 1;
        const current = adapter.joltage;
        while (i + j < adapters.len) : (j += 1) {
            const adjacent = adapters[i + j].joltage;
            const difference = adjacent - current;
            if (difference > 3) break;
            if (difference == 1 and j == 1) diff_1 += 1;
            if (difference == 3 and j == 1) diff_3 += 1;
            adapter.connections[difference - 1] = j;
            if (difference == 3) break;
        }
    }

    var i: usize = 2;
    while (i <= adapters.len) : (i += 1) {
        const idx = adapters.len - i;
        const adapter = &adapters[idx];
        for (adapter.connections) |j| {
            if (j > 0) adapter.arrangements += adapters[idx + j].arrangements;
        }
    }

    try n.out.print("{}\n{}\n", .{ diff_1 * diff_3, adapters[0].arrangements });
}
