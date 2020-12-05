const std = @import("std");
const util = @import("util");
const input = @embedFile("5.txt");

pub fn main(n: util.Utils) !void {
    var id_list = util.list(u10);
    var lines = std.mem.tokenize(input, "\n");
    while (lines.next()) |line| {
        var id: u10 = 0;
        comptime var i = 0;
        inline while (i < 7) : (i += 1) {
            if (line[i] == 'B') {
                id |= 1 << (9 - i);
            }
        }
        inline while (i < 10) : (i += 1) {
            if (line[i] == 'R') {
                id |= 1 << (9 - i);
            }
        }
        try id_list.append(n.arena, id);
    }
    std.sort.sort(u10, id_list.items, {}, comptime std.sort.desc(u10));
    const our_id = blk: {
        var prev = id_list.items[0];
        for (id_list.items[1..]) |id| {
            if (prev - id == 2)
                break :blk id + 1;
            prev = id;
        } else return error.Unexpected;
    };
    try n.out.print("{}\n{}\n", .{id_list.items[0], our_id});
}
