const std = @import("std");
const util = @import("util");
const input = @embedFile("18.txt");

const Token = union(enum) {
    group: []const Token,
    literal: u64,
    add: void,
    mul: void,

    fn eval1(self: Token) u64 {
        switch (self) {
            .group => |g| {
                std.debug.assert(g.len % 2 == 1);
                var accum = g[0].eval1();
                var expr: []const Token = g[1..];
                while (expr.len > 0) : (expr = expr[2..]) {
                    switch (expr[0]) {
                        .add => accum += expr[1].eval1(),
                        .mul => accum *= expr[1].eval1(),
                        else => unreachable,
                    }
                }
                return accum;
            },
            .literal => |n| return n,
            else => unreachable,
        }
    }

    fn eval2(self: Token) u64 {
        switch (self) {
            .group => |g| {
                std.debug.assert(g.len % 2 == 1);
                var accum = g[0].eval2();
                var expr: []const Token = g[1..];
                while (expr.len > 0) {
                    switch (expr[0]) {
                        .add => {
                            accum += expr[1].eval2();
                            expr = expr[2..];
                        },
                        .mul => {
                            var i: usize = 2;
                            while (expr[i..].len >= 2) {
                                switch (expr[i]) {
                                    .add => i += 2,
                                    .mul => break,
                                    else => unreachable,
                                }
                            }
                            accum *= (Token{ .group = expr[1..i] }).eval2();
                            expr = expr[i..];
                        },
                        else => unreachable,
                    }
                }
                return accum;
            },
            .literal => |n| return n,
            else => unreachable,
        }
    }
};

const tokens: []const Token = comptime blk: {
    @setEvalBranchQuota(input.len * 10);
    var tokens_: []const Token = &[_]Token{};
    for (util.lines(input)) |line| {
        var expr = line;
        var parse_int: ?u64 = null;
        var group_stack: []const []const Token = &[_][]const Token{};
        var current_group: []const Token = &[_]Token{};
        while (true) {
            if (parse_int) |*int| {
                if (expr.len == 0 or expr[0] < '0' or expr[0] > '9') {
                    current_group = current_group ++ [_]Token{.{ .literal = int.* }};
                    parse_int = null;
                } else {
                    int.* *= 10;
                    int.* += c - '0';
                    expr = expr[1..];
                }
            } else if (expr.len > 0) {
                switch (expr[0]) {
                    ' ' => {},
                    '+' => current_group = current_group ++ [_]Token{.add},
                    '*' => current_group = current_group ++ [_]Token{.mul},
                    '(' => {
                        group_stack = group_stack ++ [_][]const Token{current_group};
                        current_group = &[_]Token{};
                    },
                    ')' => {
                        const token = [_]Token{.{ .group = current_group }};
                        current_group = group_stack[group_stack.len - 1] ++ token;
                        group_stack = group_stack[0..(group_stack.len - 1)];
                    },
                    '0'...'9' => parse_int = expr[0] - '0',
                    else => unreachable,
                }
                expr = expr[1..];
            } else break;
        }
        tokens_ = tokens_ ++ [_]Token{.{ .group = current_group }};
    }
    break :blk tokens_;
};

pub fn main(n: util.Utils) !void {
    var part_1: u64 = 0;
    var part_2: u64 = 0;
    for (tokens) |token| {
        part_1 += token.eval1();
        part_2 += token.eval2();
    }
    try n.out.print("{}\n{}\n", .{ part_1, part_2 });
}
