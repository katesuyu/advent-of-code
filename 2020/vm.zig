const std = @import("std");
const util = @import("util");

pub const Instr = enum(u32) {
    jmp, acc, nop,
};

pub fn Interpreter(comptime src: []const u8, comptime mixin: anytype) type {
    @setEvalBranchQuota(src.len * 1000);
    comptime var bytecode: []u32 = &[_]u32{};
    comptime {
        var index: usize = 0;
        var lines = std.mem.tokenize(src, "\n");
        while (lines.next()) |line| {
            std.debug.assert(line.len >= 5);
            const param = util.parseInt(i32, line[4..]) catch unreachable;
            const instr = @field(Instr, line[0..3]);
            var new_slice: [bytecode.len + 2]u32 = bytecode[0..bytecode.len].* ++ [_]u32{
                @enumToInt(instr),
                @bitCast(u32, param),
            };
            bytecode = new_slice[0..];
        }
        var idx = 0;
        while (idx < bytecode.len) : (idx += 2) {
            if (bytecode[idx] != @enumToInt(Instr.acc)) {
                const target_idx = idx + @as(comptime_int, @bitCast(i32, bytecode[idx + 1])) * 2;
                bytecode[idx + 1] = @intCast(u32, target_idx);
            }
        }
    }
    return struct {
        /// The current index into the interpreted bytecode.
        index: usize = 0,
        /// The value of the accumulator set by the `acc` instruction.
        accum: i32 = 0,
        /// Optional metadata to be stored within the interpreter state.
        mixin: Mixin = mixin_default,
        /// The bytecode currently being considered for execution.
        bytecode: [bytecode.len]u32 = bytecode_init,

        /// The bytecode used to initialize the interpreter.
        pub const bytecode_init: [bytecode.len]u32 = bytecode[0..bytecode.len].*;

        /// The type of the mixin field (which optionally contains an update hook).
        pub const Mixin = if (@TypeOf(mixin) == type) mixin else mixin(Self);

        const should_update = Mixin != void and @hasDecl(Mixin, "update");
        const mixin_default: Mixin = if (Mixin == void)
            {}
        else if (@hasDecl(Mixin, "default_value"))
            Mixin.default_value
        else
            undefined;

        pub usingnamespace if (Mixin != void and @hasDecl(Mixin, "namespace")) Mixin.namespace else struct {};

        inline fn updateMixin(self: *Self) !bool {
            comptime std.debug.assert(should_update);
            return Mixin.update(self);
        }

        /// Execute one instruction from the interpreter, returning `true` if
        /// the interpreter executed an instruction, and `false` if it halted.
        /// By default, this should not return `false` until the interpreter
        /// reaches the end of instructions, but this can be overriden by mixins.
        pub fn step(self: *Self) !bool {
            if (should_update and (try self.updateMixin()) == false)
                return false;
            if (self.index >= self.bytecode.len)
                return should_update;

            const instr = self.getInstr();
            switch (instr) {
                .acc => self.accum = try std.math.add(i32, self.accum, self.param_i32()),
                .nop, .jmp => {},
            }

            self.index = if (instr == .jmp)
                self.param_usize()
            else
                self.index + 2;

            return true;
        }

        /// Get the instruction id for the current index.
        pub inline fn getInstr(self: Self) Instr {
            return @intToEnum(Instr, self.bytecode[self.index]);
        }

        /// Get the parameter for the current instruction as a u32.
        pub inline fn param_u32(self: Self) u32 {
            return self.bytecode[self.index + 1];
        }

        /// Get the parameter for the current instruction as an i32.
        pub inline fn param_i32(self: Self) i32 {
            return @bitCast(i32, self.param_u32());
        }

        /// Get the parameter for the current instruction as a usize.
        pub inline fn param_usize(self: Self) usize {
            return @intCast(usize, self.param_u32());
        }

        const Self = @This();
    };
}
