const std = @import("std");
const assert = std.debug.assert;

const MAX_INPUT = 16384;

fn is_marker(candidate: []const u8) bool {
    var freq = [1]bool{false} ** 256;
    for (candidate) |c| {
        freq[c] = if (freq[c]) return false else true;
    }
    return true;
}

fn get_som_pos(input: []const u8, len: u32) u32 {
    var i: u32 = 0;
    while (i < input.len - 3) : (i += 1) {
        if (is_marker(input[i .. i + len])) {
            return i + len;
        }
    }
    return 0;
}

pub fn main() !void {
    var buf: [MAX_INPUT]u8 = undefined;
    const len = try std.io.getStdIn().reader().read(&buf);
    const input = buf[0..len];

    std.debug.print("Start of Marker position: {}\n", .{get_som_pos(input)});
}

const expect = std.testing.expect;

const sample1 = "mjqjpqmgbljsphdztnvjfqwrcgsmlb";
const sample2 = "bvwbjplbgvbhsrlpgdmjqwftvncz";
const sample3 = "nppdvjthqldpwncqszvftbrmjlhg";
const sample4 = "nznrnfrfntjfmvfwmzdfjlvtqnbhcprsg";
const sample5 = "zcfzfwzzqfrljwzlrfnpqdbhtmscgvjw";

test "sample1" {
    try expect(get_som_pos(sample1, 4) == 7);
    try expect(get_som_pos(sample1, 14) == 19);
}

test "sample2" {
    try expect(get_som_pos(sample2, 4) == 5);
    try expect(get_som_pos(sample2, 14) == 23);
}

test "sample3" {
    try expect(get_som_pos(sample3, 4) == 6);
    try expect(get_som_pos(sample3, 14) == 23);
}

test "sample4" {
    try expect(get_som_pos(sample4, 4) == 10);
    try expect(get_som_pos(sample4, 14) == 29);
}

test "sample5" {
    try expect(get_som_pos(sample5, 4) == 11);
    try expect(get_som_pos(sample5, 14) == 26);
}

const aoc_input = @embedFile("input.txt");
test "aoc input" {
    try expect(get_som_pos(aoc_input, 4) == 1598);
    try expect(get_som_pos(aoc_input, 14) == 2414);
}
