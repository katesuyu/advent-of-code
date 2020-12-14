const std = @import("std");
const util = @import("util");
const input = @embedFile("14.txt");

const MaskValueInstr = struct {
    addr: u36,
    value: u36,
};

const MaskAddrInstr = struct {
    addr: u36,
    value: u36,
    mask: u36,
};

usingnamespace comptime blk: {
    @setEvalBranchQuota(input.len * 100);
    var bitwise_or: u36 = 0;
    var value_mask: u36 = undefined;
    var addr_mask: u36 = undefined;
    var mask_value_buf: []const [2]comptime_int = &[_][2]comptime_int{};
    var mask_addr_buf: []const [3]comptime_int = &[_][3]comptime_int{};
    var lines = std.mem.tokenize(input, "\n");
    while (lines.next()) |line| {
        if (std.mem.eql(u8, line[0..4], "mem[")) {
            var idx_end = 4;
            while (line[idx_end] != ']')
                idx_end += 1;
            const idx = util.parseUint(u36, line[4..idx_end]) catch unreachable;
            const value = util.parseUint(u36, line[(idx_end + 4)..]) catch unreachable;
            const masked_value = (value & value_mask) | bitwise_or;
            const masked_addr = (idx & addr_mask) | bitwise_or;
            mask_value_init = mask_value_init ++ [_][2]comptime_int{
                [_]comptime_int{idx, masked_value},
            };
            mask_addr_init = mask_addr_init ++ [_][3]comptime_int{
                [_]comptime_int{masked_addr, value, value_mask},
            };
        } else {
            std.debug.assert(line.len == 36 + 7);
            const mask_str = line[7..];
            bitwise_or = 0;
            value_mask = 0;
            addr_mask = 0;
            for (mask_str) |c, j| {
                switch (c) {
                    'X' => value_mask |= 1 << (35 - j),
                    '0' => addr_mask |= 1 << (35 - j),
                    '1' => bitwise_or |= 1 << (35 - j),
                    else => unreachable,
                }
            }
        }
    }
    var mask_values_: []const MaskValueInstr = &[_]MaskValueInstr{};
    var mask_addrs_: []const MaskAddrInstr = &[_]MaskValueInstr{};
    for (mask_value_buf) |memset|
        mask_values_ = mask_values_ ++ [_]MaskValueInstr{.{
            .addr = memset[0],
            .value = memset[1],
        }};
    for (mask_addr_buf) |memset|
        mask_addrs_ = mask_addrs_ ++ [_]MaskAddrInstr{.{
            .addr = memset[0],
            .value = memset[1],
            .mask = memset[2],
        }};
    break :blk struct {
        pub const mask_values = mask_values_[0..mask_values_.len].*;
        pub const mask_addrs = mask_addrs_[0..mask_addrs_.len].*;
    };
};

pub fn main(n: util.Utils) !void {
    var memory = util.map(u36, u36);
    try memory.ensureCapacity(n.arena, 1_000_000);

    var part_1: u64 = 0;
    for (mask_values) |instr|
        memory.putAssumeCapacity(instr.addr, instr.value);
    for (memory.entries()) |entry|
        part_1 += entry.value;

    var part_2: u64 = 0;
    memory.clearRetainingCapacity();
    for (mask_addrs) |instr| {
        var bits: u36 = instr.mask;
        var bit_count: u36 = @popCount(instr.mask);
        while (bit_count > 0) : (bit_count -= 1) {
            const target_bit = ~(@as(u36, 1) << @ctz(u36, bits));
        }
    }

    try n.out.print("{}\n{}\n", .{ part_1, part_2 });
}

fn permuteAll(memory: *util.Map(u36, u36), addr: u36, mask: u36) void {

}
