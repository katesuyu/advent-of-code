const std = @import("std");
const util = @import("util");
const input = @embedFile("16.txt");

const TicketRule = struct {
    name: []const u8,
    ranges: [4]u32,

    fn inRange(self: TicketRule, int: u32) bool {
        return (int >= self.ranges[0] and int <= self.ranges[1]) or
            (int >= self.ranges[2] and int <= self.ranges[3]);
    }
};

const input_sections: [3][]const u8 = comptime blk: {
    @setEvalBranchQuota(input.len * 5);
    var sections: [3][]const u8 = [_][]const u8{ input, undefined, undefined };
    var section_idx = 0;
    while (section_idx < 2) : (section_idx += 1) {
        var prev_char = 0;
        const section = sections[section_idx];
        for (section) |c, i| {
            defer prev_char = c;
            if (c == prev_char and c == '\n') {
                sections[section_idx] = section[0..i];
                sections[section_idx + 1] = section[(i + 1)..];
                break;
            }
        } else unreachable;
    }
    for (.{ &sections[1], &sections[2] }) |section| {
        while (section.*[0] != '\n')
            section.* = section.*[1..];
        section.* = section.*[1..];
    }
    break :blk sections;
};

const ticket_rules: [ticket_rules_.len]TicketRule = ticket_rules_[0..ticket_rules_.len].*;
const ticket_rules_ = comptime blk: {
    @setEvalBranchQuota(input.len * 20);
    var rules: []const TicketRule = &[_]TicketRule{};
    var rules_str = input_sections[0];
    while (rules_str.len > 0) {
        var ticket_rule: TicketRule = undefined;
        for (rules_str) |c, i| {
            if (c == ':') {
                ticket_rule.name = rules_str[0..i];
                rules_str = rules_str[(i + 2)..];
                break;
            }
        } else unreachable;
        for (.{ 0, 2 }) |offset| {
            for (rules_str) |c, i| {
                if (c == '-') {
                    ticket_rule.ranges[offset] = util.parseUint(u32, rules_str[0..i]) catch unreachable;
                    rules_str = rules_str[(i + 1)..];
                    break;
                }
            } else unreachable;
            for (rules_str) |c, i| {
                if (c == ' ' or c == '\n') {
                    ticket_rule.ranges[offset + 1] = util.parseUint(u32, rules_str[0..i]) catch unreachable;
                    if (c == ' ') rules_str = rules_str[(i + 4)..];
                    if (c == '\n') rules_str = rules_str[(i + 1)..];
                    break;
                }
            } else unreachable;
        }
        rules = rules ++ [_]TicketRule{ticket_rule};
    }
    break :blk rules;
};

const my_ticket = comptime blk: {
    @setEvalBranchQuota(input_sections[1].len * 20);
    var entries: []const u32 = &[_]u32{};
    var ticket_str = input_sections[1];
    while (ticket_str.len > 0) {
        for (ticket_str) |c, i| {
            if (c == ',' or c == '\n') {
                const entry = util.parseUint(u32, ticket_str[0..i]) catch unreachable;
                ticket_str = ticket_str[(i + 1)..];
                entries = entries ++ [_]u32{entry};
                break;
            }
        } else unreachable;
    }
    break :blk entries[0..entries.len].*;
};

const nearby_tickets = comptime blk: {
    @setEvalBranchQuota(input_sections[2].len * 20);
    const Ticket = [my_ticket.len]u32;
    var tickets: []const Ticket = &[_]Ticket{};
    var ticket_str = input_sections[2];
    while (ticket_str.len > 0) {
        var ticket: Ticket = undefined;
        for (ticket) |*entry| {
            for (ticket_str) |c, i| {
                if (c == ',' or c == '\n') {
                    entry.* = util.parseUint(u32, ticket_str[0..i]) catch unreachable;
                    ticket_str = ticket_str[(i + 1)..];
                    break;
                }
            } else unreachable;
        }
        tickets = tickets ++ [_]Ticket{ticket};
    }
    break :blk tickets[0..tickets.len].*;
};

pub fn main(n: util.Utils) !void {
    var error_rate: u32 = 0;
    var departure_product: u64 = 1;
    var valid_for: [my_ticket.len][]usize = undefined;
    var valid_for_buf = comptime blk: {
        var indices: [ticket_rules.len]usize = undefined;
        for (indices) |*x, i|
            x.* = i;
        break :blk [_][ticket_rules.len]usize{indices} ** my_ticket.len;
    };
    inline for ([_]void{{}} ** my_ticket.len) |_, i| {
        valid_for[i] = &valid_for_buf[i];
    }
    outer: while (true) : (error_rate = 0) {
        for (nearby_tickets) |ticket| {
            const prev_error_rate = error_rate;
            for (ticket) |entry, i| {
                for (ticket_rules) |rule| {
                    if (rule.inRange(entry)) break;
                } else error_rate += entry;
            }
            if (error_rate != prev_error_rate) continue;
            for (ticket) |entry, i| {
                var j: usize = 0;
                var rules = valid_for[i];
                if (rules.len == 0) continue;
                while (j < rules.len) {
                    if (!ticket_rules[rules[j]].inRange(entry)) {
                        rules[j] = rules[rules.len - 1];
                        rules.len -= 1;
                    } else j += 1;
                }
                valid_for[i] = rules;
                if (rules.len == 1) {
                    const idx = rules[0];
                    if (std.mem.startsWith(u8, ticket_rules[idx].name, "departure"))
                        departure_product *= my_ticket[i];
                    for (valid_for) |*ruleset, k| {
                        j = 0;
                        while (j < ruleset.len) : (j += 1) {
                            if (ruleset.*[j] == idx) {
                                ruleset.*[j] = ruleset.*[ruleset.len - 1];
                                ruleset.len -= 1;
                                break;
                            }
                        }
                    }
                    continue :outer;
                }
            }
        }
        break;
    }
    try n.out.print("{}\n{}\n", .{ error_rate, departure_product });
}
