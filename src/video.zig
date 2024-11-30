const c = @import("c.zig");
const g = @import("globals.zig"); // -lobals
const gl = @import("gl");

const tex = struct {
    var coords = [_]c.GLfloat{
        0, 1,
        0, 0,
        1, 1,
        1, 0,
    };
    var id: c.GLuint = undefined;
};
var vertices = [_]c.GLfloat{ // zig fmt: off
    -1.0, -1.0, // left-bottom
    -1.0,  1.0, // left-top
     1.0, -1.0, // right-bottom
     1.0,  1.0, // right-top
}; // zig fmt: on
pub var window: *c.GLFWwindow = undefined;

pub fn configure(geom: *const c.retro_game_geometry) !void {
    _ = geom;
}

pub fn deinit() void {}

pub fn refresh(data: ?*const anyopaque, width: c_uint, height: c_uint, pitch: usize) callconv(.C) void {
    _ = .{ data, width, height, pitch };
}

pub fn render() void {
    gl.BindTexture(gl.TEXTURE_2D, g.v.tex.id);

    gl.EnableClientState(gl.VERTEX_ARRAY);
    gl.EnableClientState(gl.VERTEX_ARRAY);

    gl.VertexPointer(2, gl.FLOAT, 0, &g.v.vertices);
    gl.TexCoordPointer(2, gl.FLOAT, 0, &g.v.tex.coords);

    gl.DrawArrays(gl.TRIANGLE_STRIP, 0, 4);
}
