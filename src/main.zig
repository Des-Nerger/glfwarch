const Globals = @import("Globals.zig");
const c = @import("c.zig");
const debug = std.debug;
const fmt = std.fmt;
const heap = std.heap;
const mem = std.mem;
const path = std.fs.path;
const process = std.process;
const std = @import("std");

pub fn die(comptime format: []const u8, args: anytype) noreturn {
    debug.print(format ++ "\n", args);
    process.exit(c.EXIT_FAILURE);
}

var g = Globals{}; // -lobals

pub fn main() !void {
    var gpa = heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    g.allocator = gpa.allocator();

    const args = try process.argsAlloc(g.allocator);
    defer process.argsFree(g.allocator, args);
    if (args.len < 3)
        die(
            "usage: {s} <core> <game> [-s default-scale] [-l load-savestate] [-d save-savestate]",
            .{path.basename(args[0])},
        );

    if (c.glfwInit() == c.GLFW_FALSE)
        die("Failed to initialize glfw", .{});
    defer c.glfwTerminate();

    var savestatel, var savestated = [_][:0]const u8{""} ** 2;
    {
        var opts = args[3..];
        while (opts.len > 0) : (opts = opts[1..]) {
            if (mem.eql(u8, opts[0], "-s"))
                g.scale = @floatFromInt(try fmt.parseInt(i16, opts[1], 10))
            else if (mem.eql(u8, opts[0], "-l"))
                savestatel = opts[1]
            else if (mem.eql(u8, opts[0], "-d"))
                savestated = opts[1];
        }
    }

    try g.coreLoad(args[1]);
    defer g.coreUnload();

    g.coreLoadGame(args[2]);
    defer {
        g.audioDeinit();
        g.videoDeinit();
    }

    if (!mem.eql(u8, savestatel, "")) {
        debug.print("savestatel = {s}\n", .{savestatel});
        // TODO
    }

    // :main_loop

    if (!mem.eql(u8, savestated, "")) {
        debug.print("savestated = {s}\n", .{savestated});
        // TODO
    }
}
