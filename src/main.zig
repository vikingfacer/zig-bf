const std = @import("std");
const interpreter = @import("./interpreter.zig");
const compile = @import("./compile.zig");

const stdout = std.io.getStdOut().writer();
const stdin = std.io.getStdIn().reader();

pub fn main() !void {
    const args = std.os.argv;
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const leaked = gpa.deinit();
    }
    try interpreter.interperate(&gpa.allocator, stdin, stdout);
}
