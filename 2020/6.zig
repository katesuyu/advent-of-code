const std = @import("std");
const util = @import("util");
const input = @embedFile("6.txt");

pub fn main(n: util.Utils) !void {
    var groups = std.mem.split(input, "\n\n");
    var any_yes_responses: usize = 0;
    var all_yes_responses: usize = 0;
    while (groups.next()) |group| {
        var num_polls: usize = 0;
        var yes_responses = [_]usize{0} ** 26;
        var polls = std.mem.tokenize(group, "\n");
        while (polls.next()) |poll| {
            num_polls += 1;
            for (poll) |c| {
                const i: usize = (try util.expectRange(c, 'a', 'z')) - 'a';
                if (yes_responses[i] == 0) {
                    any_yes_responses += 1;
                }
                yes_responses[i] += 1;
            }
        }
        for (yes_responses) |count| {
            if (count == num_polls) {
                all_yes_responses += 1;
            }
        }
    }
    try n.out.print("{}\n{}\n", .{any_yes_responses, all_yes_responses});
}
