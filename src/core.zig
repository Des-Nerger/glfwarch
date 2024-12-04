const DynLib = std.DynLib;
const c = @import("c.zig");
const core = @This();
const debug = std.debug;
const die = @import("main.zig").die;
const fs = std.fs;
const g = @import("globals.zig"); // -lobals
const process = std.process;
const std = @import("std");

usingnamespace struct {
    usingnamespace struct {
        pub var game_data: []u8 = &.{};
    };
    pub fn maybeFreeGameData() void {
        const data = &core.game_data;
        if (data.len != 0) {
            g.allocator.free(data.*);
            data.* = &.{};
        }
    }
};

pub fn load(dynlib_file: [:0]const u8) !void {
    g.retro.lib = try DynLib.open(dynlib_file);
    inline for (@typeInfo(@TypeOf(g.retro)).@"struct".fields) |field| {
        const t = @typeInfo(field.type);
        if (t == .pointer and @typeInfo(t.pointer.child) == .@"fn")
            @field(g.retro, field.name) = g.retro.lib.lookup(
                field.type,
                "retro_" ++ field.name,
            ) orelse
                return error.SymbolNotFound;
    }
    g.retro.set_environment(struct {
        fn environment(cmd: c_uint, data: ?*anyopaque) callconv(.C) bool {
            switch (cmd) {
                // c.RETRO_ENVIRONMENT_GET_LOG_INTERFACE => {},
                // c.RETRO_ENVIRONMENT_GET_CAN_DUPE => {},
                c.RETRO_ENVIRONMENT_SET_PIXEL_FORMAT => {
                    const fmt = @as(*c.retro_pixel_format, @alignCast(@ptrCast(data.?))).*;

                    if (fmt > c.RETRO_PIXEL_FORMAT_RGB565)
                        return false;

                    g.v.setPixelFormat(fmt);
                },
                // c.RETRO_ENVIRONMENT_GET_SYSTEM_DIRECTORY,
                // c.RETRO_ENVIRONMENT_GET_SAVE_DIRECTORY => {},
                else => {
                    return false;
                },
            }
            return true;
        }
    }.environment);
    g.retro.set_video_refresh(g.v.refresh);
    g.retro.set_input_poll(g.in.poll);
    g.retro.set_input_state(g.in.state);
    g.retro.set_audio_sample(g.audio.sample);
    g.retro.set_audio_sample_batch(g.audio.sampleBatch);
    g.retro.init();
    g.retro.is_initialized = true;
    debug.print("Core loaded\n", .{});
}

pub fn loadGame(filename: [:0]const u8) !void {
    var info = c.retro_game_info{
        .path = filename,
    };
    system: {
        var system = c.retro_system_info{};
        g.retro.get_system_info(&system);
        if (system.need_fullpath)
            break :system;
        core.maybeFreeGameData();
        core.game_data = fs.cwd().readFileAlloc(
            g.allocator,
            filename,
            try process.totalSystemMemory() * 3 / 4,
        ) catch |err|
            die("Failed to load content '{s}': {}", .{ filename, err });
        info.data, info.size = .{ core.game_data.ptr, core.game_data.len };
    }
    if (!g.retro.load_game(&info))
        die("The core failed to load the content.", .{});

    var av = c.retro_system_av_info{};
    g.retro.get_system_av_info(&av);
    try g.v.configure(&av.geometry);
    try g.audio.init(av.timing.sample_rate);
}

pub fn unload() void {
    defer g.retro.lib.close();
    defer core.maybeFreeGameData();
    if (!g.retro.is_initialized)
        return;
    g.retro.deinit();
    g.retro.is_initialized = false;
}
