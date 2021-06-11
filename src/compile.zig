const std = @import("std");

const util = @import("./util.zig");

pub fn compiler(filename: []u8, allocator: *std.mem.Allocator) !void {
    const bf_file = try std.fs.cwd().openFile(
        filename,
        .{ .read = true },
    );
    defer bf_file.close();
    errdefer bf_file.close();

    const program = try bf_file.readToEndAlloc(allocator, 30000);
    defer allocator.free(program);
    errdefer allocator.free(program);

    std.debug.print("{}\n", .{program});

    const piled_file = try std.fs.cwd().createFile(
        "a.asm",
        .{ .read = false },
    );
    defer piled_file.close();
    errdefer piled_file.close();

    try compile_asm(program, piled_file, allocator);
}

const preamble =
    \\section .data
    \\SYS_EXIT equ 60
    \\SUCCESS equ 9
    \\
    \\SYS_WRITE equ 1
    \\STDOUT equ 1
    \\
    \\SYS_READ equ 0
    \\STDIN equ 0
    \\
    \\ARRAY times 30000 db 0
    \\
    \\global _start
    \\
    \\section .text
    \\
    \\_start:
    \\    mov r12, ARRAY
    \\
;

const exit =
    \\mov rax, SYS_EXIT
    \\mov rdi, SUCCESS
    \\syscall
    \\
;

fn compile_asm(prog: []u8, out: std.fs.File, alloc: *std.mem.Allocator) !void {
    _ = try out.write(preamble);
    var loops = std.ArrayList(u32).init(alloc);
    defer loops.deinit();

    for (prog) |token, i| {
        switch (token) {
            '[' => {
                const bi = util.findPair(
                    prog[i..prog.len],
                    '[',
                    ']',
                );
                const loop_stmt = try std.fmt.allocPrint(
                    alloc,
                    "\ncmp byte [r12], 0\nje l{}\nl{}:\n",
                    .{ bi.? + i, i },
                );
                defer alloc.free(loop_stmt);
                _ = try out.write(loop_stmt);
            },
            ']' => {
                const rprog = prog[0..(i + 1)];
                std.mem.reverse(u8, rprog);
                const bi = util.findPair(
                    rprog,
                    ']',
                    '[',
                );
                std.mem.reverse(u8, rprog);
                const loopend_stmt = try std.fmt.allocPrint(
                    alloc,
                    "cmp byte [r12], 0\njne l{}\nl{}:\n",
                    .{ i - bi.?, i },
                );
                _ = try out.write(loopend_stmt);
                defer alloc.free(loopend_stmt);
            },
            '>' => {
                const move_r = "add r12, 1\n";
                _ = try out.write(move_r);
            },
            '<' => {
                const move_l = "sub r12, 1\n";
                _ = try out.write(move_l);
            },
            '-' => {
                const sub_b = "sub byte [r12], 1\n";
                _ = try out.write(sub_b);
            },
            '+' => {
                const add_b = "add byte [r12], 1\n";
                _ = try out.write(add_b);
            },
            ',' => {
                _ = try out.write(
                    \\mov rax, SYS_READ
                    \\mov rdi, STDIN
                    \\mov rsi, r12
                    \\mov rdx, 1
                    \\syscall
                    \\
                );
            },
            '.' => {
                _ = try out.write(
                    \\mov rax, SYS_WRITE
                    \\mov rdi, STDOUT
                    \\mov rsi, r12
                    \\mov rdx, 1
                    \\syscall
                    \\
                );
            },
            else => {},
        }
    }
    _ = try out.write(exit);
}
