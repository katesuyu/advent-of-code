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
            num_valid += @boolToInt(document.isValid());
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
    cid: ?[]const u8 = null,

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
        inline for (std.meta.fields(Document)) |info| {
            const is_cid = comptime std.mem.eql(u8, info.name, "cid");
            if (!is_cid and @field(self, info.name) == null)
                return false;
        }
        return true;
    }

    fn isValid(self: Document) bool {
        const byr = std.fmt.parseUnsigned(u32, self.byr.?, 10) catch return false;
        const iyr = std.fmt.parseUnsigned(u32, self.iyr.?, 10) catch return false;
        const eyr = std.fmt.parseUnsigned(u32, self.eyr.?, 10) catch return false;

        if (byr < 1920 or byr > 2002) return false;
        if (iyr < 2010 or iyr > 2020) return false;
        if (eyr < 2020 or eyr > 2030) return false;

        const hgt = self.hgt.?;
        if (std.mem.endsWith(u8, hgt, "cm")) {
            const height = std.fmt.parseUnsigned(u32, hgt[0 .. hgt.len - 2], 10) catch return false;
            if (height < 150 or height > 193) return false;
        } else if (std.mem.endsWith(u8, hgt, "in")) {
            const height = std.fmt.parseUnsigned(u32, hgt[0 .. hgt.len - 2], 10) catch return false;
            if (height < 59 or height > 76) return false;
        } else return false;

        const hcl = self.hcl.?;
        if (hcl.len != 7 or hcl[0] != '#') return false;
        for (hcl[1..]) |c| switch (c) {
            '0'...'9', 'a'...'f' => {},
            else => return false,
        };

        if (self.pid.?.len != 9) return false;
        for (self.pid.?) |c| switch (c) {
            '0'...'9' => {},
            else => return false,
        };

        return validEyeColor(self.ecl.?);
    }

    fn validEyeColor(str: []const u8) bool {
        inline for (.{ "amb", "blu", "brn", "gry", "grn", "hzl", "oth" }) |color| {
            if (std.mem.eql(u8, str, color)) return true;
        }
        return false;
    }
};
