const std = @import("std");

var best3 = [_]u64{ 0, 0, 0 };

pub fn maybe_update_best3(total: u64) void {
    // Potentially insert total into best3 in sorted order
    if (total > best3[0]) {
        best3[2] = best3[1];
        best3[1] = best3[0];
        best3[0] = total;
    } else if (total > best3[1]) {
        best3[2] = best3[1];
        best3[1] = total;
    } else if (total > best3[2]) {
        best3[2] = total;
    }
}

pub fn main() !void {
    var stdin = std.io.bufferedReader(std.io.getStdIn().reader());
    var stdout = std.io.bufferedWriter(std.io.getStdOut().writer());

    var cur_total: u64 = 0;
    var buf: [80]u8 = undefined;
    while (try stdin.reader().readUntilDelimiterOrEof(buf[0..], '\n')) |line| {
        if (line.len > 0) {
            const calories = try std.fmt.parseInt(u64, line, 10);
            cur_total += calories;
        } else {
            maybe_update_best3(cur_total);
            cur_total = 0;
        }
    }
    // catch last record before EOF
    if (cur_total != 0) {
        maybe_update_best3(cur_total);
    }
    try std.fmt.format(stdout.writer(), "{} + {} + {} = {}\n", .{ best3[0], best3[1], best3[2], best3[0] + best3[1] + best3[2] });
    try stdout.flush();
}
