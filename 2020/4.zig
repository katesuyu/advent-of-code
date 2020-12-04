const std = @import("std");
const util = @import("util");
const input = @embedFile("4.txt");

pub fn main(n: util.Utils) !void {
    var num_complete: usize = 0;
    var num_valid: usize = 0;

    var batches = std.mem.split(input, "\n\n");
    while (batches.next()) |batch| {
        const document = Document.parse(batch);
        if (document.isComplete()) {
            num_complete += 1;
            if (document.isValid())
                num_valid += 1;
        }
    }

    try n.out.print("{}\n{}\n", .{ num_complete, num_valid });
}

const Document = struct {
    byr: ?[]const u8 = null,
    iyr: ?[]const u8 = null,
    eyr: ?[]const u8 = null,
    hgt: ?[]const u8 = null,
    hcl: ?[]const u8 = null,
    ecl: ?[]const u8 = null,
    pid: ?[]const u8 = null,

    fn parse(str: []const u8) Document {
        var document = Document{};
        var fields = std.mem.tokenize(str, " \n");
        while (fields.next()) |field| {
            inline for (std.meta.fields(Document)) |info| {
                if (std.mem.eql(u8, field[0..3], info.name)) {
                    @field(document, info.name) = field[4..];
                }
            }
        }
        return document;
    }

    fn isComplete(self: Document) bool {
        inline for (std.meta.fields(Document)) |info|
            if (@field(self, info.name) == null) return false;
        return true;
    }

    fn isValid(self: Document) bool {
        @setEvalBranchQuota(3000);

        if (!validRange(self.byr.?, 1920, 2002)) return false;
        if (!validRange(self.iyr.?, 2010, 2020)) return false;
        if (!validRange(self.eyr.?, 2020, 2030)) return false;

        const hgt = self.hgt.?;
        if (std.mem.endsWith(u8, hgt, "cm")) {
            if (!validRange(hgt[0..(hgt.len - 2)], 150, 193)) return false;
        } else if (std.mem.endsWith(u8, hgt, "in")) {
            if (!validRange(hgt[0..(hgt.len - 2)], 59, 76)) return false;
        } else return false;

        if (!util.isMatch("#[0-9a-f]{6}", self.hcl.?)) return false;
        if (!util.isMatch("[0-9]{9}", self.pid.?)) return false;
        return util.isMatch("amb|blu|brn|gry|grn|hzl|oth", self.ecl.?);
    }

    fn validRange(str: []const u8, min: u32, max: u32) bool {
        const int = util.parse_u32(str) catch return false;
        return int >= min and int <= max;
    }
};
