const DynLib = std.DynLib;
const Type = std.builtin.Type;
const c = @import("c.zig");
const debug = std.debug;
const mem = std.mem;
const std = @import("std");
const stdout = std.io.getStdOut().writer();

scale: f32 = 3,
allocator: mem.Allocator = undefined,
retro: struct {
    fn Retro(comptime field_tags: []const @Type(Type.enum_literal)) type {
        var fields: [field_tags.len]Type.StructField = undefined;
        for (0.., &fields) |i, *field| {
            const field_name = @tagName(field_tags[i]);
            const fn_ptr_type = *const @TypeOf(@field(c, "retro_" ++ field_name));
            field.* = Type.StructField{
                .name = field_name,
                .type = fn_ptr_type,
                .default_value = null,
                .is_comptime = false,
                .alignment = @alignOf(fn_ptr_type),
            };
        }
        /////////////////////////////
        var s = @typeInfo(struct { // type_-truct
            lib: DynLib,
            initialized: bool,
            // <-- the generated fields are being inserted here
        }).@"struct";
        ////////////////////////////
        s.fields = &(s.fields[0..].* ++ fields);
        return @Type(Type{ .@"struct" = s });
    }
}.Retro(&.{
    .init,
    .deinit,
    .api_version,
    .get_system_info,
    .get_system_av_info,
    .set_controller_port_device,
    .reset,
    .run,
    .serialize_size,
    .serialize,
    .unserialize,
    .load_game,
    .unload_game,
}) = undefined,

pub fn videoDeinit(g: *@This()) void { // -lobals
    _ = g;
}

pub fn audioDeinit(g: *@This()) void { // -lobals
    _ = g;
}

pub fn coreLoad(g: *@This(), dynlib_file: [:0]const u8) !void { // -lobals
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
    debug.print("g.retro.api_version() == {}\n", .{g.retro.api_version()});
    // g.retro.set_environment(core_environment);
    // g.retro.set_video_refresh(core_video_refresh);
    // g.retro.set_input_poll(core_input_poll);
    // g.retro.set_input_state(core_input_state);
    // g.retro.set_audio_sample(core_audio_sample);
    // g.retro.set_audio_sample_batch(core_audio_sample_batch);
    // g.retro.init();
    g.retro.initialized = true;
    try stdout.writeAll("Core loaded\n");
}

pub fn coreLoadGame(g: *@This(), filename: [:0]const u8) void { // -lobals
    _, _ = .{ g, filename };
}

pub fn coreUnload(g: *@This()) void { // -lobals
    g.retro.lib.close();
    if (!g.retro.initialized)
        return;
    // g.retro.deinit();
    g.retro.initialized = false;
}
