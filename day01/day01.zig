const std = @import("std");
const expect = std.testing.expect;

fn maybe_update_best3(best3: []u32, total: u32) void {
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

fn parse_and_get_best3(reader: anytype) ![3]u32 {
    var best3 = [_]u32{ 0, 0, 0 };

    var cur_total: u32 = 0;
    var buf: [80]u8 = undefined;
    while (try reader.readUntilDelimiterOrEof(buf[0..], '\n')) |line| {
        if (line.len > 0) {
            const calories = try std.fmt.parseUnsigned(u32, line, 10);
            cur_total += calories;
        } else {
            maybe_update_best3(&best3, cur_total);
            cur_total = 0;
        }
    }

    // catch last record before EOF
    if (cur_total != 0) {
        maybe_update_best3(&best3, cur_total);
    }
    return best3;
}

pub fn main() !void {
    var buf: [16384]u8 = undefined;
    const len = try std.io.getStdIn().reader().read(buf[0..]);

    const input = buf[0..len];

    var fis = std.io.fixedBufferStream(input);
    const best3 = try parse_and_get_best3(fis.reader());

    std.debug.print("{} + {} + {} = {}\n", .{ //
        best3[0], best3[1], best3[2], best3[0] + best3[1] + best3[2],
    });
}

test "sample" {
    const input =
        \\1000
        \\2000
        \\3000
        \\
        \\4000
        \\
        \\5000
        \\6000
        \\
        \\7000
        \\8000
        \\9000
        \\
        \\10000
    ;
    var fis = std.io.fixedBufferStream(input);
    const best3 = try parse_and_get_best3(fis.reader());
    try expect(best3[0] == 24000);
    try expect(best3[1] == 11000);
    try expect(best3[2] == 10000);
}
