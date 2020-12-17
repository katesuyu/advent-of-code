const std = @import("std");
const util = @import("util");
const input = util.gridRows(@embedFile("17.txt"));

const CubeState = enum(u1) {
    inactive = 0,
    active = 1,
};

const World = struct {
    buf: [2]Buf = buf_init,

    const Buf = [30][30][30][30]CubeState;
    const buf_init = comptime blk: {
        var buf = [_][30][30][30]CubeState{
            [_][30][30]CubeState{
                [_][30]CubeState{
                    [_]CubeState{
                        .inactive,
                    } ** 30,
                } ** 30,
            } ** 30,
        } ** 30;
        for (input) |row, x| {
            for (row) |state, y| {
                buf[x + 12][y + 12][15][15] = switch (state) {
                    '.' => .inactive,
                    '#' => .active,
                    else => unreachable,
                };
            }
        }
        break :blk [_]Buf{buf} ** 2;
    };

    fn tick(self: *World, idx: u1, comptime @"4d": bool) void {
        const n_iter = [_]comptime_int{ -1, 0, 1 };
        const w_iter = if (@"4d") n_iter else [_]comptime_int{0};
        for (self.buf[idx]) |*x_axis, x| {
            if (x == 0 or x == 29) continue;
            for (x_axis) |*y_axis, y| {
                if (y == 0 or y == 29) continue;
                for (y_axis) |*z_axis_, z| {
                    const z_axis = if (@"4d") z_axis_ else z_axis_[15..16];
                    if (z == 0 or z == 29) continue;
                    for (z_axis) |state, w_| {
                        if (@"4d") if (w_ == 0 or w_ == 29) continue;
                        const w = if (@"4d") w_ else 15;
                        var neighbors: u8 = 0;
                        inline for (n_iter) |dx| {
                            inline for (n_iter) |dy| {
                                inline for (n_iter) |dz| {
                                    inline for (w_iter) |dw| {
                                        if (dx == 0 and dy == 0 and dz == 0 and dw == 0)
                                            continue;
                                        const x2 = if (dx == -1) x - 1 else x + dx;
                                        const y2 = if (dy == -1) y - 1 else y + dy;
                                        const z2 = if (dz == -1) z - 1 else z + dz;
                                        const w2 = if (dw == -1) w - 1 else w + dw;
                                        neighbors += @enumToInt(self.buf[idx][x2][y2][z2][w2]);
                                    }
                                }
                            }
                        }
                        self.buf[~idx][x][y][z][w] = switch (state) {
                            .inactive => if (neighbors == 3) CubeState.active else CubeState.inactive,
                            .active => if (neighbors == 2 or neighbors == 3) CubeState.active else CubeState.inactive,
                        };
                    }
                }
            }
        }
    }

    fn count(self: World, idx: u1, comptime @"4d": bool) u32 {
        var accum: u32 = 0;
        for (self.buf[idx]) |*x_axis| {
            for (x_axis) |*y_axis| {
                for (y_axis) |*z_axis_| {
                    const z_axis = if (@"4d") z_axis_ else z_axis_[15..16];
                    for (z_axis) |state| {
                        accum += @enumToInt(state);
                    }
                }
            }
        }
        return accum;
    }
};

pub fn main(n: util.Utils) !void {
    var world = World{};
    var results: [2]u32 = undefined;
    inline for ([_]bool{ false, true }) |@"4d"| {
        var idx: u1 = 0;
        for ([_]void{{}} ** 6) |_| {
            defer idx +%= 1;
            world.tick(idx, @"4d");
        }
        results[@boolToInt(@"4d")] = world.count(idx, @"4d");
        if (!@"4d") world = .{};
    }
    try n.out.print("{}\n{}\n", .{ results[0], results[1] });
}
