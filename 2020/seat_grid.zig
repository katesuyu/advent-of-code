const std = @import("std");
const util = @import("util");

pub fn Grid(comptime grid: anytype) type {
    comptime std.debug.assert(grid.len > 0 and grid[0].len > 0);
    comptime std.debug.assert(@TypeOf(grid) == [grid.len][grid[0].len]u8);
    return struct {
        buf: [2][height][width]u8 = comptime blk: {
            @setEvalBranchQuota(height * 10);
            var buf: [height][width]u8 = undefined;
            buf[0] = [_]u8{'.'} ** width;
            buf[height - 1] = buf[0];
            for (buf[1..(height - 1)]) |*bytes, y|
                bytes.* = [_]u8{'.'} ++ grid[y] ++ [_]u8{'.'};
            break :blk [_][height][width]u8{ buf, buf };
        },
        const width = grid[0].len + 2;
        const height = grid.len + 2;

        pub fn update(
            self: *@This(),
            idx: u1,
            comptime updateFn: fn (
                buf: *const [height][width]u8,
                x: usize,
                y: usize,
            ) bool,
        ) ?usize {
            const src = &self.buf[idx];
            const dest = &self.buf[idx ^ 1];
            var num_occupied: ?usize = 0;
            var y: usize = 1;
            while (y < height - 1) : (y += 1) {
                var x: usize = 1;
                while (x < width - 1) : (x += 1) {
                    if (src[y][x] == '.')
                        continue;
                    dest[y][x] = if (updateFn(src, x, y)) '#' else 'L';
                    if (src[y][x] != dest[y][x]) {
                        num_occupied = null;
                    }
                    if (dest[y][x] == '#' and num_occupied != null) {
                        num_occupied.? += 1;
                    }
                }
            }
            return num_occupied;
        }

        pub fn adjacentRule(buf: *const [height][width]u8, x: usize, y: usize) bool {
            var num_adjacent: usize = 0;
            inline for (.{ -1, 0, 1 }) |dx| {
                inline for (.{ -1, 0, 1 }) |dy| {
                    if (dx == 0 and dy == 0)
                        continue;
                    const new_x = if (dx == -1) x - 1 else x + dx;
                    const new_y = if (dy == -1) y - 1 else y + dy;
                    if (buf[new_y][new_x] == '#') {
                        num_adjacent += 1;
                    }
                }
            }
            return switch (num_adjacent) {
                0 => true,
                4...8 => false,
                else => buf[y][x] == '#',
            };
        }

        pub fn visibleRule(buf: *const [height][width]u8, x: usize, y: usize) bool {
            var num_visible: usize = 0;
            inline for (.{ -1, 0, 1 }) |dx| {
                inline for (.{ -1, 0, 1 }) |dy| {
                    if (dx == 0 and dy == 0)
                        continue;
                    var new_x = x;
                    var new_y = y;
                    while (new_x > 0 and new_x < width - 1 and new_y > 0 and new_y < height - 1) {
                        new_x = if (dx == -1) new_x - 1 else new_x + dx;
                        new_y = if (dy == -1) new_y - 1 else new_y + dy;
                        if (buf[new_y][new_x] == '#') num_visible += 1;
                        if (buf[new_y][new_x] != '.') break;
                    }
                }
            }
            return switch (num_visible) {
                0 => true,
                5...8 => false,
                else => buf[y][x] == '#',
            };
        }
    };
}
