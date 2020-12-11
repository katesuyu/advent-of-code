const std = @import("std");
const util = @import("util");
const input = @embedFile("5.txt");

const id_list = comptime blk: {
    @setEvalBranchQuota(input.len * 10);
    var idx = 0;
    var buf: []const u10 = &[_]u10{};
    while (idx < input.len) : (idx += 11) {
        const line = input[idx..][0..10].*;
        var id: u10 = 0;
        for (line) |c, i| {
            if (c == 'B' or c == 'R') {
                id |= 1 << (9 - i);
            }
        }
        buf = buf ++ [_]u10{id};
    }
    var sorted = buf[0..buf.len].*;
    std.sort.sort(u10, &sorted, {}, std.sort.desc(u10));
    break :blk sorted;
};

pub fn main(n: util.Utils) !void {
    const our_id = blk: {
        var prev = id_list[0];
        for (id_list[1..]) |id| {
            if (prev - id == 2)
                break :blk id + 1;
            prev = id;
        } else return error.BadInput;
    };
    try n.out.print("{}\n{}\n", .{id_list[0], our_id});
}
