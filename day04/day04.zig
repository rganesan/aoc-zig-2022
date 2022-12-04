const std = @import("std");

// Max section number is 100, so use a u100 type as a bitmask for assigned sections.
// This makes it very easy to use bitwise operators to find overlaps
fn get_range_mask(range_str: []const u8) !u100 {
    var range_iter = std.mem.split(u8, range_str, "-");
    const start = try std.fmt.parseUnsigned(u100, range_iter.next().?, 10);
    const end = try std.fmt.parseUnsigned(u100, range_iter.next().?, 10);
    var range: u100 = 0;
    var n = start - 1;
    while (n < end) {
        var mask: u100 = undefined;
        _ = @shlWithOverflow(u100, 1, @intCast(u7, n), &mask);
        range |= mask;
        n += 1;
    }
    // std.debug.print("range: {s} {x}\n", .{ range_str, n });
    return range;
}

// find section supersets
fn part1(input: []const u8) !u32 {
    var supersets: u32 = 0;

    var iter = std.mem.split(u8, input, "\n");
    while (iter.next()) |line| {
        if (line.len == 0) break;
        var section_iter = std.mem.split(u8, line, ",");
        const section1_str = section_iter.next().?;
        const section2_str = section_iter.next().?;
        const section1 = try get_range_mask(section1_str);
        const section2 = try get_range_mask(section2_str);
        if (section1 | section2 == section1 or section1 | section2 == section2) {
            // std.debug.print("sections: {s} {s}\n", .{ section1_str, section2_str });
            supersets += 1;
        }
    }
    // std.debug.print("Part1 score: {}\n", .{supersets});
    return supersets;
}

// find section overlaps
fn part2(input: []const u8) !u32 {
    var overlaps: u32 = 0;

    var iter = std.mem.split(u8, input, "\n");
    while (iter.next()) |line| {
        if (line.len == 0) break;
        var section_iter = std.mem.split(u8, line, ",");
        const section1_str = section_iter.next().?;
        const section2_str = section_iter.next().?;
        const section1 = try get_range_mask(section1_str);
        const section2 = try get_range_mask(section2_str);
        if (section1 & section2 != 0) {
            // std.debug.print("sections: {s} {s}\n", .{ section1_str, section2_str });
            overlaps += 1;
        }
    }
    // std.debug.print("Part2 score: {}\n", .{overlaps});
    return overlaps;
}

pub fn main() !void {
    var buf: [16384]u8 = undefined;
    const len = try std.io.getStdIn().reader().read(&buf);
    const input = buf[0..len];
    std.debug.print("scores: {} {}\n", .{ try part1(input), try part2(input) });
}

const expect = std.testing.expect;

const sample =
    \\2-4,6-8
    \\2-3,4-5
    \\5-7,7-9
    \\2-8,3-7
    \\6-6,4-6
    \\2-6,4-8
;

test "part1" {
    try expect(try part1(sample) == 2);
}
test "part2" {
    try expect(try part2(sample) == 4);
}
