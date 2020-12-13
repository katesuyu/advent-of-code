const std = @import("std");
const util = @import("util");
const input = @embedFile("13.txt");

usingnamespace comptime blk: {
    @setEvalBranchQuota(input.len * 20);
    var offset: u32 = 0;
    var buf: []const [2]u32 = &[_][2]u32{};
    var lines = std.mem.tokenize(input, "\n");
    const timestamp = util.parseUint(u32, lines.next().?) catch unreachable;
    var id_iter = std.mem.split(lines.next().?, ",");
    while (id_iter.next()) |id| {
        defer offset += 1;
        if (!std.mem.eql(u8, id, "x")) {
            const int = util.parseUint(u32, id) catch unreachable;
            buf = buf ++ [_][2]u32{.{int, offset}};
        }
    }
    var sorted = buf[0..buf.len].*;
    std.sort.sort([2]u32, &sorted, {}, struct {
        fn impl(_: void, a: [2]u32, b: [2]u32) bool {
            return a[0] > b[0];
        }
    }.impl);
    for (sorted) |*entry| {
        const id: comptime_int = entry[0];
        const offset_: comptime_int = entry[1];
        entry[1] = @mod(-offset_, id);
    }
    break :blk struct {
        pub const earliest = timestamp;
        pub const id_pairs = sorted;
    };
};

pub fn main(n: util.Utils) !void {
    var departure: u32 = comptime std.math.maxInt(u32);
    var bus_id: u32 = undefined;
    for (id_pairs) |id| {
        const multiplier = std.math.divCeil(u32, earliest, id[0]) catch unreachable;
        const timestamp = multiplier * id[0];
        if (timestamp < departure) {
            departure = timestamp;
            bus_id = id[0];
        }
    }

    var addend: u64 = id_pairs[0][0];
    var timestamp: u64 = comptime blk: {
        const multiplier = @divFloor(@as(u64, 100_000_000_000_000), id_pairs[0][0]);
        break :blk multiplier * id_pairs[0][0] + id_pairs[0][1];
    };
    for (id_pairs[1..]) |id_pair| {
        const id = id_pair[0];
        const modulus = id_pair[1];
        while (timestamp % id != modulus)
            timestamp += addend;
        addend *= id;
    }

    try n.out.print("{}\n{}\n", .{bus_id * (departure - earliest), timestamp});
}
