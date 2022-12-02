const std = @import("std");
const expect = std.testing.expect;

const RPS = enum(u8) {
    Rock = 1,
    Paper = 2,
    Scissors = 3,
};

const Result = enum {
    Lose,
    Draw,
    Win,
};

fn get_play(char: u8) !RPS {
    return switch (char) {
        'A', 'X' => .Rock,
        'B', 'Y' => .Paper,
        'C', 'Z' => .Scissors,
        else => unreachable,
    };
}

fn part1(reader: anytype) !u32 {
    var score: u32 = 0;
    var buf: [80]u8 = undefined;
    while (try reader.readUntilDelimiterOrEof(buf[0..], '\n')) |line| {
        var iter = std.mem.split(u8, line, " ");
        const him = try get_play(iter.next().?[0]);
        const me = try get_play(iter.next().?[0]);
        // std.debug.print("{} {}\n", .{ him, me });
        score += @enumToInt(me);
        if (me == him) { // draw
            score += 3;
        } else if (me == .Rock) {
            if (him == .Scissors) { // win
                score += 6;
            }
        } else if (me == .Paper) {
            if (him == .Rock) { // win
                score += 6;
            }
        } else { // scissors
            if (him == .Paper) {
                score += 6;
            }
        }
    }
    return score;
}

fn get_result(char: u8) !Result {
    return switch (char) {
        'X' => .Lose,
        'Y' => .Draw,
        'Z' => .Win,
        else => unreachable,
    };
}

fn part2(reader: anytype) !u32 {
    var buf: [80]u8 = undefined;
    var total: u32 = 0;

    while (try reader.readUntilDelimiterOrEof(buf[0..], '\n')) |line| {
        var score: u32 = 0;
        var iter = std.mem.split(u8, line, " ");
        const him = try get_play(iter.next().?[0]);
        const result = try get_result(iter.next().?[0]);

        var me: RPS = undefined;
        switch (result) {
            .Lose => {
                score += 0;
                me = switch (him) {
                    .Rock => RPS.Scissors,
                    .Paper => RPS.Rock,
                    .Scissors => RPS.Paper,
                };
            },
            .Draw => {
                score += 3;
                me = him;
            },
            .Win => {
                score += 6;
                me = switch (him) {
                    .Rock => RPS.Paper,
                    .Paper => RPS.Scissors,
                    .Scissors => RPS.Rock,
                };
            },
        }
        score += @enumToInt(me);
        total += score;
    }
    return total;
}

pub fn main() !void {
    var buf: [16384]u8 = undefined;
    const len = try std.io.getStdIn().reader().read(buf[0..]);

    const input = buf[0..len];

    var part1_fis = std.io.fixedBufferStream(input);
    std.debug.print("Part1 score: {}\n", .{try part1(part1_fis.reader())});

    var part2_fis = std.io.fixedBufferStream(input);
    std.debug.print("Part2 score: {}\n", .{try part2(part2_fis.reader())});
}

test "part1" {
    const buf = "A Y\nB X\nC Z\n";
    var fis = std.io.fixedBufferStream(buf);
    try expect(try part1(fis.reader()) == 15);
}

test "part2" {
    const buf = "A Y\nB X\nC Z\n";
    var fis = std.io.fixedBufferStream(buf);
    try expect(try part2(fis.reader()) == 12);
}
