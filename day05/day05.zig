const std = @import("std");
const assert = std.debug.assert;

const MAX_INPUT = 16384;

const MAX_STACKS = 10;

// Use an array list for a stack of crates so we can easily push and pop items. The
// input numbers the stacks from 1 but the code use 0 based indexing.
const Stack = std.ArrayList(u8);

// Get top of stack. LIFO indicates whether move are in LIFO or in order
fn get_TOS(allocator: std.mem.Allocator, input: []const u8, lifo: bool) ![]const u8 {
    var iter = std.mem.split(u8, input, "\n");

    // Preinitialize MAX_STACKS stacks. This makes the code less cluttered
    var stacks: [MAX_STACKS]Stack = undefined;
    var s: u32 = 0;
    while (s < MAX_STACKS) {
        stacks[s] = Stack.init(allocator);
        s += 1;
    }

    // parse stacks of crates
    var nstacks: u32 = 0;
    while (iter.next()) |line| {
        if (line.len == 0) break;
        if (line[1] == '1') continue; // stack numbers; TODO: validate this
        s = 0;
        var i: u32 = 0;
        while (i < line.len) {
            if (line[i] == '[') {
                try stacks[s].insert(0, line[i + 1]);
            }
            i += 4; // need to hard-code to handle completed stacks
            s += 1;
        }
        if (nstacks != 0) assert(nstacks == s);
        nstacks = s;
    }

    // now parse moves
    while (iter.next()) |line| {
        if (line.len == 0) break;
        var moves = std.mem.split(u8, line, " ");
        _ = moves.next(); // "move"
        var n = try std.fmt.parseUnsigned(u8, moves.next().?, 10); // n crates
        _ = moves.next(); // "from"
        const from = try std.fmt.parseUnsigned(u8, moves.next().?, 10) - 1;
        _ = moves.next(); // "to"
        const to = try std.fmt.parseUnsigned(u8, moves.next().?, 10) - 1;

        // save position in "to" stack for ordered insert
        var pos = stacks[to].items.len;
        while (n > 0) {
            const crate = stacks[from].pop();
            if (lifo) {
                try stacks[to].append(crate);
            } else {
                try stacks[to].insert(pos, crate);
            }
            n -= 1;
        }
    }

    var tos = Stack.init(allocator);
    defer tos.deinit();
    for (stacks) |stack, i| {
        if (i == nstacks) {
            break;
        }
        try tos.append(stack.items[stack.items.len - 1]);
        stack.deinit(); // free the stack
    }
    // std.debug.print("{s}\n", .{tos.items});
    return tos.toOwnedSlice();
}

pub fn main() !void {
    var buf: [MAX_INPUT]u8 = undefined;
    const len = try std.io.getStdIn().reader().read(&buf);
    const input = buf[0..len];
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    std.debug.print("Top of Stack LIFO: {s}\n", .{try get_TOS(allocator, input, true)});
    std.debug.print("Top of Stack Ordered: {s}\n", .{try get_TOS(allocator, input, false)});
}

const expect = std.testing.expect;

const sample =
    \\    [D]    
    \\[N] [C]    
    \\[Z] [M] [P]
    \\ 1   2   3
    \\
    \\move 1 from 2 to 1
    \\move 3 from 1 to 3
    \\move 2 from 2 to 1
    \\move 1 from 1 to 2
;

test "sample lifo moves" {
    const tos = try get_TOS(std.testing.allocator, sample, true);
    defer std.testing.allocator.free(tos);
    try expect(std.mem.eql(u8, tos, "CMZ"));
}

test "sample ordered moves" {
    const tos = try get_TOS(std.testing.allocator, sample, false);
    defer std.testing.allocator.free(tos);
    try expect(std.mem.eql(u8, tos, "MCD"));
}

const aoc_input = @embedFile("input.txt");
test "input lifo moves" {
    const tos = try get_TOS(std.testing.allocator, aoc_input, true);
    defer std.testing.allocator.free(tos);
    try expect(std.mem.eql(u8, tos, "CWMTGHBDW"));
}

test "input ordered moves" {
    const tos = try get_TOS(std.testing.allocator, aoc_input, false);
    try expect(std.mem.eql(u8, tos, "SSCGWJCRB"));
    std.testing.allocator.free(tos);
}
