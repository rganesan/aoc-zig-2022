const std = @import("std");

// get priority for item, (prio - 1) is used to index an item in an array
fn get_prio(c: u8) u32 {
    return if (std.ascii.isUpper(c)) c - 'A' + 26 + 1 else c - 'a' + 1;
}

const nprio = 52;

// find sum of priorities of duplicate items
fn part1(input: []const u8) u32 {
    var sum: u32 = 0;

    var iter = std.mem.split(u8, input, "\n");
    while (iter.next()) |line| {
        const first = line[0 .. line.len / 2];
        const second = line[line.len / 2 ..];
        var compartment1 = [_]bool{false} ** nprio;
        var compartment2 = [_]bool{false} ** nprio;

        for (first) |c| {
            const i = get_prio(c) - 1;
            compartment1[i] = true;
        }
        for (second) |c| {
            const i = get_prio(c) - 1;
            compartment2[i] = true;
            if (compartment1[i]) { // dupe!
                sum += get_prio(c);
                // std.debug.print("Dupe: {c} priority: {}\n", .{ c, get_prio(c) });
                break;
            }
        }
    }
    return sum;
}

// find sum of priorities of badges in groups of 3
fn part2(input: []const u8) u32 {
    var sum: u32 = 0;
    var elf_items = [_][nprio]bool{
        [_]bool{false} ** nprio,
        [_]bool{false} ** nprio,
        [_]bool{false} ** nprio,
    };

    var elf: u32 = 0;
    var iter = std.mem.split(u8, input, "\n");
    while (iter.next()) |line| {
        for (line) |c| {
            const i = get_prio(c) - 1;
            elf_items[elf][i] = true;
            if (elf == 2 and elf_items[0][i] and elf_items[1][i]) {
                // found badge
                // std.debug.print("Badge: {c}\n", .{c});
                sum += get_prio(c);
                break;
            }
        }
        elf += 1;
        if (elf > 2) {
            elf = 0;
            elf_items = [_][nprio]bool{
                [_]bool{false} ** nprio,
                [_]bool{false} ** nprio,
                [_]bool{false} ** nprio,
            };
        }
    }

    return sum;
}

pub fn main() !void {
    var buf: [16384]u8 = undefined;
    const len = try std.io.getStdIn().reader().read(&buf);
    const input = buf[0..len];

    std.debug.print("Part1 score: {}\n", .{part1(input)});
    std.debug.print("Part2 score: {}\n", .{part2(input)});
}

const expect = std.testing.expect;

const sample =
    \\vJrwpWtwJgWrhcsFMMfFFhFp
    \\jqHRNqRjqzjGDLGLrsFMfFZSrLrFZsSL
    \\PmmdzqPrVvPwwTWBwg
    \\wMqvLMZHhHMvwLHjbvcjnnSBnvTQFn
    \\ttgJtRGJQctTZtZT
    \\CrZsJsPPZsGzwwsLwLmpwMDw
;

test "part1" {
    try expect(part1(sample) == 157);
}
test "part2" {
    try expect(part2(sample) == 70);
}
