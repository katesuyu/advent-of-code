const std = @import("std");
const util = @import("util");
const input = comptime util.gridRows(@embedFile("11.txt"));

const Grid = @import("seat_grid.zig").Grid(input);

pub fn main(n: util.Utils) !void {
    var results = [_]?usize{null, null};
    inline for (.{ Grid.adjacentRule, Grid.visibleRule }) |rule, i| {
        var idx: u1 = 0;
        var grid = Grid{};
        while (results[i] == null) : (idx ^= 1) {
            results[i] = grid.update(idx, rule);
        }
    }
    try n.out.print("{}\n{}\n", .{ results[0].?, results[1].? });
}
