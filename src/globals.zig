const DynLib = std.DynLib;
const Type = std.builtin.Type;
const c = @import("c.zig");
const mem = std.mem;
const std = @import("std");

pub const audio = @import("audio.zig");
pub const core = @import("core.zig");
pub const input = @import("input.zig");
pub const video = @import("video.zig");
pub var scale: f32 = 3;
pub var allocator: mem.Allocator = undefined;
pub var retro: struct {
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
            is_initialized: bool,
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
    .set_environment,
    .set_video_refresh,
    .set_input_poll,
    .set_input_state,
    .set_audio_sample,
    .set_audio_sample_batch,
}) = undefined;
