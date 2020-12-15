const std = @import("std");
const util = @import("util");
const input = @embedFile("15.txt");

const starting = comptime blk: {
    var buf: []const u32 = &[_]u32{};
    var numbers = std.mem.split(input[0..(input.len - 1)], ",");
    while (numbers.next()) |number|
        buf = buf ++ [_]u32{
            util.parseUint(u32, number) catch unreachable,
        };
    break :blk buf[0..buf.len].*;
};

pub fn main(n: util.Utils) !void {
    var numbers = util.map(u32, u32);
    try numbers.ensureCapacity(n.arena, 30_000_000);

    var num_2020: u32 = undefined;
    var previous = starting[starting.len - 1];
    var turn = @intCast(u32, starting.len) - 1;
    for (starting[0..(starting.len - 1)]) |num, i|
        numbers.putAssumeCapacity(num, @intCast(u32, i));
    while (turn < 29_999_999) : (turn += 1) {
        const entry = numbers.getOrPutAssumeCapacity(previous);
        previous = if (entry.found_existing) turn - entry.entry.value else 0;
        entry.entry.value = turn;
        if (turn == 2018) num_2020 = previous;
    }

    try n.out.print("{}\n{}\n", .{num_2020, previous});
}
