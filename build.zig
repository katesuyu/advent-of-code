const std = @import("std");
const fs = std.fs;
const mem = std.mem;
const Builder = std.build.Builder;
const Pkg = std.build.Pkg;
const cwd = std.fs.cwd;

pub fn build(b: *Builder) !void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();

    // Open the build root as an iterable directory handle.
    var build_root = try cwd().openDir(b.build_root, .{ .iterate = true });
    defer build_root.close();

    // Create a list containing each year present in the repo.
    const Year = struct { str: []const u8, int: u32 };
    var years: []const Year = blk: {
        // Create an ArrayList to allocate space for the list of years.
        var list = std.ArrayListUnmanaged(Year){};

        // Populate the list of years based on directory names.
        var iterator = build_root.iterate();
        while (try iterator.next()) |item| {
            if (item.kind == .Directory) {
                const year = std.fmt.parseUnsigned(u32, item.name, 10) catch continue;
                try list.append(b.allocator, .{
                    .str = b.dupe(item.name),
                    .int = year,
                });
            }
        }

        // Extract the years from the list and sort them in descending order.
        std.sort.sort(Year, list.items, {}, struct {
            fn impl(_: void, l: Year, r: Year) bool {
                return l.int > r.int;
            }
        }.impl);
        break :blk list.items;
    };

    // Accept a filter over the years and days to execute. If no filter is
    // provided, the latest day of the most recent year will be executed.
    const filter = b.option([]const u8, "filter", "Filter the solutions to be executed");
    if (filter == null and years.len > 0) {
        years.len = 1;
    }

    // Create a dependency listing made available to each puzzle solution.
    const ctregex = Pkg{
        .name = "ctregex",
        .path = b.pathFromRoot("deps/ctregex.zig/ctregex.zig"),
    };
    const util = Pkg{
        .name = "util",
        .path = b.pathFromRoot("util.zig"),
    };
    const deps = [_]Pkg{ctregex, util};

    // Create a listing of the puzzle solutions to be filtered and run.
    const Puzzle = struct { pkg: Pkg, day: u32 };
    var puzzles = std.AutoArrayHashMapUnmanaged(u32, []const Puzzle){};
    var num_puzzles: usize = 0;
    for (years) |year| {
        // Open the directory containing the year's solutions.
        var year_dir = try build_root.openDir(year.str, .{ .iterate = true });
        defer year_dir.close();

        // Populate this year's list of puzzle solutions.
        var list = std.ArrayListUnmanaged(Puzzle){};
        var iterator = year_dir.iterate();
        while (try iterator.next()) |item| {
            if (item.kind == .File and mem.endsWith(u8, item.name, ".zig")) {
                const name = item.name[0..(item.name.len - 4)];
                const day = std.fmt.parseUnsigned(u32, name, 10) catch continue;
                const entry = try list.addOne(b.allocator);
                entry.* = Puzzle{
                    .pkg = Pkg{
                        .name = b.fmt("{}:{}", .{ year.str, name }),
                        .path = try fs.path.resolve(b.allocator, &[_][]const u8{
                            b.build_root,
                            year.str,
                            item.name,
                        }),
                        .dependencies = &deps,
                    },
                    .day = day,
                };
                num_puzzles += 1;
            }
        }

        // Sort the year's puzzles by day in descending order.
        if (list.items.len > 0) {
            std.sort.sort(Puzzle, list.items, {}, struct {
                fn impl(_: void, l: Puzzle, r: Puzzle) bool {
                    return l.day > r.day;
                }
            }.impl);
            try puzzles.put(b.allocator, year.int, list.items);
        }
    }

    // Generate the source of the main executable based on the files present.
    const exe_src = b.addWriteFile("main.zig", blk: {
        @setEvalBranchQuota(10_000);
        var src = std.ArrayList(u8).init(b.allocator);
        const writer = src.writer();

        // Import std and ctregex, and define metadata structs.
        try writer.writeAll(
            \\const std = @import("std");
            \\const ctregex = @import("ctregex");
            \\const Utils = @import("util").Utils;
            \\
            \\const Puzzle = struct {
            \\    id: []const u8,
            \\    pkg: type,
            \\    day: u32,
            \\    year: u32,
            \\};
            \\
            \\
        );

        // If a filter is supplied, we run all puzzle solutions that match the filter.
        // Otherwise, we run the latest puzzle solution from the most recent year.
        if (filter) |filter_| {
            try writer.print(
                \\const puzzles = comptime blk: {{
                \\    @setEvalBranchQuota(5000 * {1});
                \\    const filter = "{0Z}";
                \\    var latest_year: u32 = 0;
                \\    var items: []const Puzzle = &[_]Puzzle{{}};
                \\
            , .{ filter_, num_puzzles });

            for (puzzles.entries.items) |entry| {
                try writer.writeAll("\n");
                for (entry.value) |item| {
                    try writer.print(
                        \\    if (ctregex.match(filter, .{{}}, "{0Z}") catch unreachable) |_| {{
                        \\        latest_year = {2};
                        \\        items = items ++ [_]Puzzle{{.{{
                        \\            .id = "{0Z}",
                        \\            .pkg = @import("{0Z}"),
                        \\            .day = {1},
                        \\            .year = {2},
                        \\        }}}};
                        \\    }}
                        \\
                    , .{ item.pkg.name, item.day, entry.key });
                }
                try writer.print(
                    \\    if (latest_year != {2}) {{
                    \\        if (ctregex.match(filter, .{{}}, "{2}") catch unreachable) |_| {{
                    \\            items = items ++ [_]Puzzle{{.{{
                    \\                .id = "{0Z}",
                    \\                .pkg = @import("{0Z}"),
                    \\                .day = {1},
                    \\                .year = {2},
                    \\            }}}};
                    \\        }}
                    \\    }}
                    \\
                , .{ entry.value[0].pkg.name, entry.value[0].day, entry.key });
            }
            try writer.writeAll("\n    break :blk items;\n};\n");
        } else {
            if (puzzles.entries.items.len == 0) {
                try writer.writeAll("const puzzles: []const Puzzle = &[_]Puzzle{};\n");
            } else {
                const entry = &puzzles.entries.items[0];
                try writer.print(
                    \\const puzzles: []const Puzzle = &[_]Puzzle{{.{{
                    \\    .id = "{0Z}",
                    \\    .pkg = @import("{0Z}"),
                    \\    .day = {1},
                    \\    .year = {2},
                    \\}}}};
                    \\
                , .{ entry.value[0].pkg.name, entry.value[0].day, entry.key });
            }
        }

        try writer.writeAll(
            \\
            \\pub fn main() u8 {
            \\    var status: u8 = 0;
            \\    const stdout = std.io.getStdOut().writer();
            \\    var timer = std.time.Timer.start() catch return 1;
            \\
            \\    inline for (puzzles) |puzzle, i| {
            \\        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
            \\        defer _ = gpa.deinit();
            \\
            \\        var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
            \\        defer arena.deinit();
            \\
            \\        const utils = Utils{
            \\            .arena = &arena.allocator,
            \\            .gpa = &gpa.allocator,
            \\            .out = stdout,
            \\        };
            \\
            \\        if (i > 0) std.debug.print("\n", .{});
            \\        timer.reset();
            \\
            \\        const puzzle_main = puzzle.pkg.main;
            \\        switch (@typeInfo(@typeInfo(@TypeOf(puzzle_main)).Fn.return_type.?)) {
            \\            .Void => puzzle_main(utils),
            \\            .ErrorUnion => {
            \\                const result = puzzle_main(utils) catch |err| {
            \\                    std.log.err("{}", .{@errorName(err)});
            \\                    if (@errorReturnTrace()) |trace| {
            \\                        std.debug.dumpStackTrace(trace.*);
            \\                    }
            \\                    status = 1;
            \\                };
            \\                comptime std.debug.assert(@TypeOf(result) == void);
            \\            },
            \\            else => comptime unreachable,
            \\        }
            \\
            \\        var elapsed = timer.read();
            \\        var fraction: ?u64 = null;
            \\        var unit: []const u8 = "ns";
            \\        if (elapsed > 1000) {
            \\            fraction = elapsed % 1000;
            \\            elapsed /= 1000;
            \\            unit = "μs";
            \\        }
            \\        if (elapsed > 1000) {
            \\            fraction = elapsed % 1000;
            \\            elapsed /= 1000;
            \\            unit = "ms";
            \\        }
            \\        if (elapsed > 1000) {
            \\            fraction = elapsed % 1000;
            \\            elapsed /= 1000;
            \\            unit = "s";
            \\        }
            \\        std.debug.print("info: December {}, {} ({}", .{
            \\            puzzle.day,
            \\            puzzle.year,
            \\            elapsed,
            \\        });
            \\        if (fraction) |f|
            \\            std.debug.print(".{}", .{f});
            \\        std.debug.print("{})\n", .{unit});
            \\    }
            \\    return status;
            \\}
            \\
        );

        break :blk src.items;
    });

    const exe = b.addExecutableFromWriteFileStep("advent-of-code", exe_src, "main.zig");
    exe.addPackage(ctregex);
    exe.addPackage(util);
    for (puzzles.entries.items) |entry|
        for (entry.value) |value|
            exe.addPackage(value.pkg);
    exe.setBuildMode(mode);
    exe.setTarget(target);
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args|
        run_cmd.addArgs(args);

    const run_step = b.step("run", "Build and run the application");
    run_step.dependOn(&run_cmd.step);
}
