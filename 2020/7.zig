const std = @import("std");
const util = @import("util");
const input = @embedFile("7.txt");

const Map = util.Map([]const u8, Bag);

const Bag = struct {
    contents: []const u8,
    num_contained: ?usize = null,
    has_shiny_gold: bool = false,

    fn update(self: *Bag, bags: *const Map) (std.fmt.ParseIntError || error{AssertionFailed})!void {
        if (self.num_contained != null) return;
        self.num_contained = 0;
        if (std.mem.eql(u8, self.contents, "no other bags")) return;

        var contents = std.mem.split(self.contents, ", ");
        while (contents.next()) |bag_str| {
            const num_end = try util.unwrap(std.mem.indexOf(u8, bag_str, " "));
            const name_end = try util.unwrap(std.mem.lastIndexOf(u8, bag_str, " "));
            const bag_count = try util.parseUint(u32, bag_str[0..num_end]);
            const bag_name = bag_str[(num_end + 1)..name_end];

            const entry = try util.unwrap(bags.getEntry(bag_name));
            try entry.value.update(bags);

            if (entry.value.has_shiny_gold or std.mem.eql(u8, bag_name, "shiny gold"))
                self.has_shiny_gold = true;
            self.num_contained.? += bag_count * (1 + entry.value.num_contained.?);
        }
    }
};

pub fn main(n: util.Utils) !void {
    var bags = Map{};
    var possible_containers: usize = 0;

    var lines = std.mem.tokenize(input, "\n");
    while (lines.next()) |line| {
        const name_end = try util.unwrap(std.mem.indexOf(u8, line, " bags "));
        const contents_start = name_end + " bags contain ".len;
        const contents_end = try util.unwrap(std.mem.indexOfPos(u8, line, contents_start, "."));
        try bags.put(n.arena, line[0..name_end], .{
            .contents = line[contents_start..contents_end],
        });
    }

    for (bags.items()) |*entry| {
        try entry.value.update(&bags);
        possible_containers += @boolToInt(entry.value.has_shiny_gold);
    }

    try n.out.print("{}\n{}\n", .{
        possible_containers,
        (try util.unwrap(bags.get("shiny gold"))).num_contained.?,
    });
}
