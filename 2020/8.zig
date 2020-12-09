const std = @import("std");
const util = @import("util");
const vm = @import("vm.zig");
const input = @embedFile("8.txt");

const Interpreter = vm.Interpreter(input, Mixin);

fn Mixin(comptime T: type) type {
    @setEvalBranchQuota(100 * T.bytecode_init.len);
    const instr_count = T.bytecode_init.len / 2;
    comptime var target_instr: []const u32 = &[_]u32{};
    comptime {
        var i = 0;
        while (i < T.bytecode_init.len) : (i += 2) {
            if (T.bytecode_init[i] != @enumToInt(vm.Instr.acc))
                target_instr = target_instr ++ [_]u32{i};
        }
    }
    return struct {
        executed_instr: [instr_count]bool = [_]bool{false} ** instr_count,
        target_idx: u32 = 0,

        pub const default_value = @This(){};

        pub fn update(self: *T) !bool {
            const idx = self.index / 2;
            if (idx >= instr_count)
                return false;
            if (self.mixin.executed_instr[idx])
                return error.InfiniteLoop;
            self.mixin.executed_instr[idx] = true;
            return true;
        }

        pub const namespace = struct {
            pub fn runUntilLoop(self: *T) !void {
                while (self.step() catch |err| switch (err) {
                    error.InfiniteLoop => return,
                    else => return err,
                }) {}
                return;
            }

            pub fn runNewState(self: *T) !bool {
                const target_idx = self.mixin.target_idx;
                try util.expect(target_idx < target_instr.len);
                self.accum = 0;
                self.index = 0;
                self.mixin = .{ .target_idx = target_idx };
                swapInstr(&self.bytecode[target_instr[target_idx]]);
                defer swapInstr(&self.bytecode[target_instr[target_idx]]);
                defer self.mixin.target_idx += 1;
                while (self.step() catch |err| switch (err) {
                    error.InfiniteLoop => return true,
                    else => return err,
                }) {}
                return false;
            }
        };

        fn swapInstr(target: *u32) void {
            target.* = switch (target.*) {
                @enumToInt(vm.Instr.jmp) => @enumToInt(vm.Instr.nop),
                @enumToInt(vm.Instr.nop) => @enumToInt(vm.Instr.jmp),
                else => unreachable,
            };
        }
    };
}

pub fn main(n: util.Utils) !void {
    var interpreter = Interpreter{};
    try interpreter.runUntilLoop();
    const part_1 = interpreter.accum;

    while (try interpreter.runNewState()) {}
    const part_2 = interpreter.accum;

    try n.out.print("{}\n{}\n", .{part_1, part_2});
}
