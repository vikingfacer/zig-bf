const std = @import("std");

const mem_size = 30000;
var memory = [_]u8{0} ** mem_size;

//! > = increases memory pointer, or moves the pointer to the right 1 block.
//! < = decreases memory pointer, or moves the pointer to the left 1 block.
//! + = increases value stored at the block pointed to by the memory pointer
//! - = decreases value stored at the block pointed to by the memory pointer
//! [ = like c while(cur_block_value != 0) loop.
//! ] = if block currently pointed to's value is not zero, jump back to [
//! , = like c getchar(). input 1 character.
//! . = like c putchar(). print 1 character to the console

fn bf(program: []u8, comptime input: anytype, comptime output: anytype) !void {
    var index: usize = 0;
    var pi: usize = 0;

    while (pi < program.len) {
        const token = program[pi];
        switch (token) {
            '>' => {
                index += 1;
                pi += 1;
            },
            '<' => {
                index -= 1;
                pi += 1;
            },
            '+' => {
                memory[index] +%= 1;
                pi += 1;
            },
            '-' => {
                memory[index] -%= 1;
                pi += 1;
            },
            '[' => {
                if (memory[index] == 0) {
                    if (findPair(program[pi..program.len], '[', ']')) |bi| {
                        pi = pi + bi;
                    }
                } else {
                    pi += 1;
                }
            },
            ']' => {
                if (memory[index] != 0) {
                    var rprogram = program[0..(pi + 1)];
                    std.mem.reverse(u8, rprogram);
                    if (findPair(rprogram, ']', '[')) |bi| {
                        pi = pi - bi;
                    }
                    std.mem.reverse(u8, rprogram);
                } else {
                    pi += 1;
                }
            },
            ',' => {
                if (input.readByte()) |value| {
                    memory[index] = value;
                } else |err| {}
                pi += 1;
            },
            '.' => {
                if (output.print("{c}", .{memory[index]})) {
                    pi += 1;
                } else |err| {
                    std.debug.warn("stdout Failed: {}\n", .{err});
                }
            },
            else => {
                pi += 1;
            },
        }
    }
}
/// returns distance index from 0 of program`
fn findPair(program: []const u8, fst: u8, snd: u8) ?usize {
    var bracket_count: usize = 0;
    for (program) |ftoken, i| {
        if (ftoken == fst) {
            bracket_count += 1;
        } else if (ftoken == snd) {
            bracket_count -= 1;
            if (bracket_count == 0) {
                return i;
            }
        }
    }
    return null;
}

test "findPair basecase" {
    const bracket = "[[[[]]]]]]";
    std.testing.expect(7 == findPair(bracket, '[', ']').?);

    const bracket1 = "[[][][][]]";
    std.testing.expect(9 == findPair(bracket1, '[', ']').?);

    const bracket2 = "[[[[[]]";
    std.testing.expect(null == findPair(bracket2, '[', ']'));

    const bracket3 = "]][[";
    std.testing.expect(3 == findPair(bracket3, ']', '[').?);

    const bracket4 = "[.+]";
    std.testing.expect(3 == findPair(bracket4, '[', ']').?);
}

fn getInput(list: *std.ArrayList(u8), comptime input: anytype) bool {
    var buffer = [_]u8{0} ** 30000;
    while (input.readUntilDelimiterOrEof(&buffer, '\n')) |line| {
        if (line) |value| {
            std.debug.warn("line: {}\n", .{line});
            list.appendSlice(value) catch |err| {
                std.debug.warn("Allocation Failed: {}", .{err});
            };
            if (value.len >= 1 and (value[value.len - 1] == '\\')) {
                continue;
            } else {
                break;
            }
        }
    } else |err| {
        std.debug.warn("Stdin Failed: {}", .{err});
        return false;
    }

    return true;
}

pub fn interperate(alloc: *std.mem.Allocator, comptime input: anytype, comptime output: anytype) !void {
    while (true) {
        var list = std.ArrayList(u8).init(alloc);
        defer list.deinit();
        if (getInput(&list, input)) {
            try bf(list.items, input, output);
        }
    }
}
