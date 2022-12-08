const std = @import("std");
const assert = std.debug.assert;

const MAX_INPUT = 16384;

fn print_grid(grid: *[99][]const u8, rows: usize) void {
    var i: usize = 0;
    while (i < rows) : (i += 1) {
        std.debug.print("{s}\n", .{grid[i]});
    }
}

// count visible trees
fn print_visible(visible: *[99][99]u8, rows: usize, cols: usize) void {
    var i: usize = 0;
    while (i < rows) : (i += 1) {
        var j: usize = 0;
        while (j < cols) : (j += 1) {
            std.debug.print("{}", .{visible[i][j]});
        }
        std.debug.print("\n", .{});
    }
}

fn count_visible(input: []const u8) usize {
    var grid: [99][]const u8 = undefined;
    var visible: [99][99]u8 = undefined;

    var iter = std.mem.split(u8, input, "\n");
    var i: usize = 0;
    var j: usize = 0;
    while (iter.next()) |line| : (i += 1) {
        if (line.len == 0) break;
        grid[i] = line;
    }

    const rows = i;
    const cols = grid[0].len;

    // Check row wise visibility
    var r: usize = 0;
    var c: usize = 0;
    var tallest: u8 = undefined;

    while (r < rows) : (r += 1) {
        // left to right
        tallest = '0' - 1;
        c = 0;
        while (c < cols) : (c += 1) {
            if (grid[r][c] > tallest) {
                visible[r][c] = 1;
                tallest = grid[r][c];
            } else {
                visible[r][c] = 0; // need to initialize
            }
        }
        // right to left
        tallest = '0' - 1;
        j = cols;
        while (j > 0) : (j -= 1) {
            c = j - 1;
            if (grid[r][c] > tallest) {
                visible[r][c] += 1;
                tallest = grid[r][c];
            }
        }
    }

    // check col wise visibility
    c = 0;
    while (c < cols) : (c += 1) {
        // top to bottom
        tallest = '0' - 1;
        r = 0;
        while (r < rows) : (r += 1) {
            if (grid[r][c] > tallest) {
                visible[r][c] += 1;
                tallest = grid[r][c];
            }
        }
        // bottom to top
        tallest = '0' - 1;
        j = rows;
        while (j > 0) : (j -= 1) {
            r = j - 1;
            if (grid[r][c] > tallest) {
                visible[r][c] += 1;
                tallest = grid[r][c];
            }
        }
    }
    var nvisible: usize = 0;
    i = 0;
    while (i < rows) : (i += 1) {
        j = 0;
        while (j < cols) : (j += 1) {
            if (visible[i][j] > 0) {
                nvisible += 1;
            }
        }
    }

    // print_grid(&grid, rows);
    // print_visible(&visible, rows, cols);
    std.debug.print("rows: {}, cols: {}, visible: {}\n", .{ rows, cols, nvisible });
    return nvisible;
}

fn look_up(grid: *const [][]const u8, row: usize, col: usize) usize {
    var cur = grid.*[row][col];
    var r: usize = row - 1;
    var score: usize = 0;
    while (r >= 0) : (r -= 1) {
        score += 1;
        if (r == 0 or grid.*[r][col] >= cur) { // blocked
            break;
        }
    }
    // std.debug.print("{},{}={}, score={}\n", .{ row, col, cur - '0', score });
    return score;
}

fn look_down(grid: *const [][]const u8, row: usize, col: usize) usize {
    var cur = grid.*[row][col];
    var r: usize = row + 1;
    var score: usize = 0;
    while (r <= grid.len - 1) : (r += 1) {
        score += 1;
        if (r == grid.len - 1 or grid.*[r][col] >= cur) {
            break;
        }
    }
    return score;
}

fn look_left(grid: *const [][]const u8, row: usize, col: usize) usize {
    var cur = grid.*[row][col];
    var c: usize = col - 1;
    var score: usize = 0;
    while (c >= 0) : (c -= 1) {
        score += 1;
        if (c == 0 or grid.*[row][c] >= cur) {
            break;
        }
    }
    return score;
}

fn look_right(grid: *const [][]const u8, row: usize, col: usize) usize {
    var cur = grid.*[row][col];
    var c: usize = col + 1;
    var score: usize = 0;
    while (c <= grid.*[0].len - 1) : (c += 1) {
        score += 1;
        if (c == grid.*[0].len - 1 or grid.*[row][c] >= cur) {
            break;
        }
    }
    return score;
}

fn get_highest_scenic_score(input: []const u8) usize {
    var pgrid: [99][]const u8 = undefined;

    var iter = std.mem.split(u8, input, "\n");
    var i: usize = 0;
    while (iter.next()) |line| : (i += 1) {
        if (line.len == 0) break;
        pgrid[i] = line;
    }

    const rows = i;
    const cols = pgrid[0].len;

    const grid = pgrid[0..pgrid[0].len];
    i = 1; // skip edge since score will be 0
    var best: usize = 0;
    while (i < rows - 1) : (i += 1) {
        var j: usize = 1;
        while (j < cols - 1) : (j += 1) {
            const score = look_up(&grid, i, j) * look_down(&grid, i, j) * look_left(&grid, i, j) * look_right(&grid, i, j);
            if (score > best) {
                best = score;
            }
        }
    }
    std.debug.print("best: {}\n", .{best});
    return best;
}

pub fn main() !void {
    var buf: [MAX_INPUT]u8 = undefined;
    const len = try std.io.getStdIn().reader().read(&buf);
    const input = buf[0..len];

    const n = count_visible(input);
    std.debug.print("Num visible: {}\n", .{n});
}

const expect = std.testing.expect;

const sample =
    \\30373
    \\25512
    \\65332
    \\33549
    \\35390
;

test "sample" {
    try expect(count_visible(sample) == 21);
    try expect(get_highest_scenic_score(sample) == 8);
}

const aoc_input = @embedFile("input.txt");
test "aoc input" {
    try expect(count_visible(aoc_input) == 1538);
    try expect(get_highest_scenic_score(aoc_input) == 8);
}
