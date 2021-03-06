const std = @import("std");
const util = @import("util");
const input = @embedFile("14.txt");

const MaskValueInstr = struct {
    addr: u36,
    value: u36,
};

const MaskAddrInstr = struct {
    addr: u36,
    mask: u36,
    value: u36,
};

usingnamespace comptime blk: {
    @setEvalBranchQuota(input.len * 20);
    var bitwise_or: u36 = 0;
    var value_mask: u36 = undefined;
    var addr_mask: u36 = undefined;
    var mask_values_buf: []const MaskValueInstr = &[_]MaskValueInstr{};
    var mask_addrs_buf: []const MaskAddrInstr = &[_]MaskAddrInstr{};
    for (util.lines(input)) |line| {
        if (std.mem.eql(u8, line[0..4], "mem[")) {
            var idx_end = 4;
            while (line[idx_end] != ']')
                idx_end += 1;
            const addr = util.parseUint(u36, line[4..idx_end]) catch unreachable;
            const value = util.parseUint(u36, line[(idx_end + 4)..]) catch unreachable;
            const masked_value = (value & value_mask) | bitwise_or;
            const masked_addr = (addr & addr_mask) | bitwise_or;
            mask_values_buf = mask_values_buf ++ [_]MaskValueInstr{.{
                .addr = addr,
                .value = masked_value,
            }};
            mask_addrs_buf = mask_addrs_buf ++ [_]MaskAddrInstr{.{
                .addr = masked_addr,
                .mask = value_mask,
                .value = value,
            }};
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
    break :blk struct {
        pub const mask_values = mask_values_buf[0..mask_values_buf.len].*;
        pub const mask_addrs = mask_addrs_buf[0..mask_addrs_buf.len].*;
    };
};

pub fn main(n: util.Utils) !void {
    var memory = util.map(u36, u36);
    try memory.ensureCapacity(n.arena, 1_000_000);

    var part_1: u64 = 0;
    for (mask_values) |instr|
        memory.putAssumeCapacity(instr.addr, instr.value);
    for (memory.items()) |entry|
        part_1 += entry.value;

    var part_2: u64 = 0;
    memory.clearRetainingCapacity();
    for (mask_addrs) |instr|
        permuteAll(&memory, instr);
    for (memory.items()) |entry|
        part_2 += entry.value;

    try n.out.print("{}\n{}\n", .{ part_1, part_2 });
}

fn permuteAll(memory: *util.Map(u36, u36), instr: MaskAddrInstr) void {
    if (instr.mask == 0) {
        memory.putAssumeCapacity(instr.addr, instr.value);
    } else {
        const target_bit = @as(u36, 1) << @ctz(u36, instr.mask);
        var new_instr = instr;
        new_instr.mask &= ~target_bit;
        permuteAll(memory, new_instr);
        new_instr.addr |= target_bit;
        permuteAll(memory, new_instr);
    }
}
