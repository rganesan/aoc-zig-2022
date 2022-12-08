const std = @import("std");
const assert = std.debug.assert;

const MAX_INPUT = 16384;
const MAX_DIR_SIZE = 100_000;
const DISK_SIZE = 70_000_000;
const SPACE_NEEDED = 30_000_000;

const File = struct {
    const Self = @This();

    name: []const u8,
    size: usize,
    fn init(name: []const u8, size: usize) Self {
        return Self{ .name = name, .size = size };
    }
};

const Dir = struct {
    const Self = @This();

    name: []const u8,
    size: usize = 0, // sum of current dir and sub-dirs
    files: std.ArrayList(File),
    dirs: std.ArrayList(Dir),

    fn init(allocator: std.mem.Allocator, name: []const u8) Self {
        return Self{
            .name = name,
            .files = std.ArrayList(File).init(allocator),
            .dirs = std.ArrayList(Dir).init(allocator),
        };
    }

    // compute size for this directory
    fn compute_size(self: *Self) void {
        assert(self.size == 0);
        for (self.dirs.items) |d| {
            self.size += d.size;
        }
        for (self.files.items) |f| {
            self.size += f.size;
        }
    }

    // recursively update size of directory tree
    fn update_tree_sizes(self: *Self) void {
        for (self.dirs.items) |*sd| {
            update_tree_sizes(sd);
        }
        self.compute_size();
    }
};

// parse directory tree from input, caller owns the memory returned
fn parse_directory_tree(allocator: std.mem.Allocator, input: []const u8) !*Dir {
    const root = try allocator.create(Dir);
    root.* = Dir.init(allocator, "/");
    var cur = root;
    var in_listing: bool = false;

    var dir_stack = std.ArrayList(*Dir).init(allocator);
    var input_iter = std.mem.tokenize(u8, input, "\n");
    while (input_iter.next()) |line| {
        // std.debug.print("line: {s}\n", .{line});
        var iter = std.mem.tokenize(u8, line, " ");
        const keyword_or_size = iter.next().?;
        if (std.mem.eql(u8, keyword_or_size, "$")) { // command
            in_listing = false;
            const cmd = iter.next().?;
            if (std.mem.eql(u8, cmd, "cd")) {
                const dirname = iter.next().?;
                if (std.mem.eql(u8, dirname, "..")) {
                    cur = dir_stack.pop();
                } else {
                    for (cur.dirs.items) |d, i| {
                        if (std.mem.eql(u8, d.name, dirname)) {
                            try dir_stack.append(cur);
                            cur = &cur.dirs.items[i];
                            break;
                        }
                    }
                }
                // std.debug.print("Cur dir: {s}\n", .{cur.name});
            } else if (std.mem.eql(u8, cmd, "ls")) {
                in_listing = true;
                // std.debug.print("directory listing for {s}\n", .{cur.name});
            }
            continue;
        }
        if (std.mem.eql(u8, keyword_or_size, "dir")) {
            const dirname = iter.next().?;
            // dirname points into input which is safe. You can't do this in rust!
            try cur.dirs.append(Dir.init(allocator, dirname));
        } else { // file
            const size = try std.fmt.parseUnsigned(usize, keyword_or_size, 10);
            const filename = iter.next().?;
            // filename points into input which is safe.
            try cur.files.append(File.init(filename, size));
        }
        assert(in_listing);
    }
    root.update_tree_sizes();
    return root;
}

fn get_total_upto_size(d: *const Dir, max: usize) usize {
    var total: usize = 0;
    for (d.dirs.items) |sd| {
        total += get_total_upto_size(&sd, max);
    }
    if (d.size <= max)
        return total + d.size;
    return total;
}

fn directory_total(root: *const Dir, max: usize) usize {
    const total = get_total_upto_size(root, max);
    std.debug.print("Total: {}\n", .{total});
    return total;
}

fn get_smallest_above_size(d: *const Dir, need: usize) usize {
    var best = d.size;
    for (d.dirs.items) |sd| {
        if (sd.size > need) {
            const candidate = get_smallest_above_size(&sd, need);
            if (candidate < best) {
                best = candidate;
            }
        }
    }
    return best;
}

fn smallest_to_free(root: *Dir, disk_size: usize, need: usize) usize {
    var tofree = need - (disk_size - root.size);
    std.debug.print("Root size: {}, free space left: {}, to free: {}\n", //
        .{ root.size, disk_size - root.size, tofree });

    const best = get_smallest_above_size(root, tofree);
    std.debug.print("best: {}\n", .{best});
    return best;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();
    const allocator = arena.allocator();

    const input = try std.io.getStdIn().readToEndAlloc(allocator, MAX_INPUT);

    var root = try parse_directory_tree(allocator, input);
    std.debug.print("Total < {}: {}\n", .{ MAX_DIR_SIZE, directory_total(root, MAX_DIR_SIZE) });
    std.debug.print("Best dir size to free: {}\n", .{smallest_to_free(root, DISK_SIZE, SPACE_NEEDED)});
}

const expect = std.testing.expect;

const sample =
    \\$ cd /
    \\$ ls
    \\dir a
    \\14848514 b.txt
    \\8504156 c.dat
    \\dir d
    \\$ cd a
    \\$ ls
    \\dir e
    \\29116 f
    \\2557 g
    \\62596 h.lst
    \\$ cd e
    \\$ ls
    \\584 i
    \\$ cd ..
    \\$ cd ..
    \\$ cd d
    \\$ ls
    \\4060174 j
    \\8033020 d.log
    \\5626152 d.ext
    \\7214296 k
;

test "sample" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const root = try parse_directory_tree(arena.allocator(), sample);
    try expect(directory_total(root, MAX_DIR_SIZE) == 95437);
    try expect(smallest_to_free(root, DISK_SIZE, SPACE_NEEDED) == 24_933_642);
}

const aoc_input = @embedFile("input.txt");
test "aoc input" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const root = try parse_directory_tree(arena.allocator(), aoc_input);
    try expect(directory_total(root, MAX_DIR_SIZE) == 1391690);
    try expect(smallest_to_free(root, DISK_SIZE, SPACE_NEEDED) == 5469168);
}
