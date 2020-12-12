const std = @import("std");
const util = @import("util");
const input = @embedFile("12.txt");

const actions = comptime blk: {
    @setEvalBranchQuota(input.len * 20);
    var buf: []const Action = &[_]Action{};
    var lines = std.mem.tokenize(input, "\n");
    while (lines.next()) |line| {
        const param: comptime_int = util.parseUint(u31, line[1..]) catch unreachable;
        const action = if (line[0] == 'R')
            Action{ .rotate = @divExact(param, 90) }
        else if (line[0] == 'L')
            Action{ .rotate = @divExact(360 - param, 90) }
        else
            Action{
                .move = .{
                    .direction = switch (line[0]) {
                        'N' => .north,
                        'E' => .east,
                        'S' => .south,
                        'W' => .west,
                        'F' => null,
                        else => unreachable,
                    },
                    .units = param,
                },
            };
        std.debug.assert(action != .rotate or action.rotate != 0);
        buf = buf ++ [_]Action{action};
    }
    break :blk buf[0..buf.len].*;
};

pub fn main(n: util.Utils) !void {
    var part_1 = DirectNavigation{};
    var part_2 = WaypointNavigation{};
    for (actions) |action| {
        part_1.apply(action);
        part_2.apply(action);
    }

    try n.out.print("{}\n{}\n", .{
        part_1.distance(),
        part_2.distance(),
    });
}

const Direction = enum(u2) {
    east, south, west, north
};

const Action = union(enum) {
    move: struct { direction: ?Direction, units: u31 },
    rotate: u2,
};

const DirectNavigation = struct {
    position: [2]i32 = [_]i32{ 0, 0 },
    direction: Direction = .east,

    fn apply(self: *@This(), action: Action) void {
        switch (action) {
            .move => |vector| {
                const units = @intCast(i32, vector.units);
                const direction = vector.direction orelse self.direction;
                const axis = &self.position[@enumToInt(direction) % 2];
                switch (direction) {
                    .east, .south => axis.* += units,
                    .west, .north => axis.* -= units,
                }
            },
            .rotate => |amount| {
                const as_int = @enumToInt(self.direction);
                self.direction = @intToEnum(Direction, as_int +% amount);
            },
        }
    }

    fn distance(self: @This()) u32 {
        return std.math.absCast(self.position[0]) + std.math.absCast(self.position[1]);
    }
};

const WaypointNavigation = struct {
    waypoint: [2]i32 = [_]i32{ 10, -1 },
    position: [2]i32 = [_]i32{ 0, 0 },

    fn apply(self: *@This(), action: Action) void {
        switch (action) {
            .move => |vector| {
                const units = @intCast(i32, vector.units);
                if (vector.direction) |direction| {
                    const axis = &self.waypoint[@enumToInt(direction) % 2];
                    switch (direction) {
                        .east, .south => axis.* += units,
                        .west, .north => axis.* -= units,
                    }
                } else {
                    self.position[0] += units * self.waypoint[0];
                    self.position[1] += units * self.waypoint[1];
                }
            },
            .rotate => |amount| {
                const waypoint = self.waypoint;
                self.waypoint = switch (amount) {
                    1 => [_]i32{ -waypoint[1], waypoint[0] },
                    2 => [_]i32{ -waypoint[0], -waypoint[1] },
                    3 => [_]i32{ waypoint[1], -waypoint[0] },
                    else => unreachable,
                };
            },
        }
    }

    fn distance(self: @This()) u32 {
        return std.math.absCast(self.position[0]) + std.math.absCast(self.position[1]);
    }
};
