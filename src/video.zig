const c = @import("c.zig");

pub fn configure(geom: *const c.retro_game_geometry) !void {
    _ = geom;
}

pub fn deinit() void {}

pub fn refresh(data: ?*const anyopaque, width: c_uint, height: c_uint, pitch: usize) callconv(.C) void {
    _, _, _, _ = .{ data, width, height, pitch };
}
