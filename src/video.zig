const assert = debug.assert;
const c = @import("c.zig");
const debug = std.debug;
const die = @import("main.zig").die;
const g = @import("globals.zig"); // -lobals
const gl = @import("gl");
const std = @import("std");
const v = @This(); // -ideo

pub usingnamespace struct {
    pub var win: *c.GLFWwindow = undefined;
};
usingnamespace struct {
    pub fn createWindow(width: c_int, height: c_int) void {
        c.glfwWindowHint(c.GLFW_CLIENT_API, c.GLFW_OPENGL_API);
        c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MAJOR, 2);
        c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MINOR, 0);
        c.glfwWindowHint(c.GLFW_RESIZABLE, c.GLFW_FALSE);

        if (c.glfwCreateWindow(width, height, "glfwarch", null, null)) |win|
            v.win = win
        else
            die("Failed to create window.", .{});

        assert(null == c.glfwSetFramebufferSizeCallback(v.win, resizeCb));

        c.glfwMakeContextCurrent(v.win);

        {
            const gl_procs = &(struct {
                var gl_procs: gl.ProcTable = undefined;
            }.gl_procs);
            if (false == gl_procs.init(c.glfwGetProcAddress))
                die("Failed to initialize zigglgen", .{});
            gl.makeProcTableCurrent(gl_procs);
        }

        c.glfwSwapInterval(1);

        debug.print("GLSL Version: {s}\n", .{gl.GetString(gl.SHADING_LANGUAGE_VERSION).?});

        gl.Enable(gl.TEXTURE_2D);

        resizeCb(v.win, width, height);
    }

    fn resizeCb(win: ?*c.GLFWwindow, width: gl.sizei, height: gl.sizei) callconv(.C) void {
        _ = win;
        gl.Viewport(0, 0, width, height);
    }
};

usingnamespace struct {
    pub var bpp: gl.uint = 0;
    pub const clip = struct {
        var w: gl.float = 0;
        var h: gl.float = 0;
    };
    pub var pitch: gl.uint = 0;
    pub const pix = struct {
        var fmt: gl.uint = 0;
        var @"type": gl.uint = 0;
    };
    pub var vertices = [_]gl.float{ // zig fmt: off
        -1.0, -1.0, // left-bottom
        -1.0,  1.0, // left-top
         1.0, -1.0, // right-bottom
         1.0,  1.0, // right-top
    }; // zig fmt: on
};
usingnamespace struct {
    pub const tex = struct {
        usingnamespace struct {
            pub var w: gl.float = 0;
            pub var h: gl.float = 0;
            pub var id: gl.uint = 0;
            pub var coords = [_]gl.float{
                0, 1,
                0, 0,
                1, 1,
                1, 0,
            };
        };
        fn refreshCoords() void {
            inline for (.{ tex.w, tex.h, v.clip.w, v.clip.h }) |dim|
                assert(0 != dim);
            const coords = &tex.coords;
            coords[1], coords[5] = .{v.clip.h / tex.h} ** 2;
            coords[4], coords[6] = .{v.clip.w / tex.w} ** 2;
        }
    };
};

fn resizeToAspect(maybe_ratio: f64, w: c_int, h: c_int) struct { c_int, c_int } { // -> width, height
    var r = .{ .w = w, .h = h }; // -eturn

    const inferred_ratio = @as(f64, @floatFromInt(w)) / @as(f64, @floatFromInt(h));
    const ratio = if (maybe_ratio > 0) maybe_ratio else inferred_ratio;

    if (inferred_ratio < 1)
        r.w = @intFromFloat(@round(@as(f64, @floatFromInt(r.h)) * ratio))
    else
        r.h = @intFromFloat(@round(@as(f64, @floatFromInt(r.w)) / ratio));

    return .{ r.w, r.h };
}

pub fn configure(geom: *const c.retro_game_geometry) !void {
    var width, var height =
        resizeToAspect(geom.aspect_ratio, @intCast(geom.base_width), @intCast(geom.base_height));

    inline for (.{ &width, &height }) |dim|
        dim.* *= g.scale;

    v.createWindow(width, height);

    if (0 != v.tex.id)
        gl.DeleteTextures(1, @as(*[1]@TypeOf(v.tex.id), &v.tex.id));

    v.tex.id = 0;

    if (0 == v.pix.fmt)
        v.pix.fmt = gl.UNSIGNED_SHORT_5_5_5_1;

    c.glfwSetWindowSize(v.win, width, height);
    c.glfwSetWindowAttrib(v.win, c.GLFW_RESIZABLE, c.GLFW_TRUE);
    c.glfwSetWindowAspectRatio(v.win, width, height);

    gl.GenTextures(1, @as(*[1]@TypeOf(v.tex.id), &v.tex.id));

    if (0 == v.tex.id)
        die("Failed to create the video texture", .{});

    v.pitch = geom.base_width * v.bpp;

    gl.BindTexture(gl.TEXTURE_2D, v.tex.id);

    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);

    gl.TexImage2D(
        gl.TEXTURE_2D,
        0,
        gl.RGBA8,
        @intCast(geom.max_width),
        @intCast(geom.max_height),
        0,
        v.pix.type,
        v.pix.fmt,
        null,
    );

    gl.BindTexture(gl.TEXTURE_2D, 0);

    v.tex.w, v.tex.h = .{ @floatFromInt(geom.max_width), @floatFromInt(geom.max_height) };
    v.clip.w, v.clip.h = .{ @floatFromInt(geom.base_width), @floatFromInt(geom.base_height) };

    v.tex.refreshCoords();
}

pub fn deinit() void {
    if (0 != v.tex.id)
        gl.DeleteTextures(1, @as(*[1]@TypeOf(v.tex.id), &v.tex.id));

    v.tex.id = 0;
}

pub fn setPixelFormat(format: c.retro_pixel_format) void {
    if (0 != v.tex.id)
        die("Tried to change pixel format after initialization.", .{});

    v.pix.fmt, v.pix.type, v.bpp = switch (format) {
        c.RETRO_PIXEL_FORMAT_0RGB1555 => .{ gl.UNSIGNED_SHORT_5_5_5_1, gl.BGRA, @sizeOf(u16) },
        c.RETRO_PIXEL_FORMAT_XRGB8888 => .{ gl.UNSIGNED_INT_8_8_8_8_REV, gl.BGRA, @sizeOf(u32) },
        c.RETRO_PIXEL_FORMAT_RGB565 => .{ gl.UNSIGNED_SHORT_5_6_5, gl.RGB, @sizeOf(u16) },
        else => die("Unknown pixel type {}", .{format}),
    };
}

pub fn refresh(maybe_data: ?*const anyopaque, width: c_uint, height: c_uint, pitch: usize) callconv(.C) void {
    const w: gl.float, const h: gl.float = .{ @floatFromInt(width), @floatFromInt(height) };
    if (v.clip.w != w or v.clip.h != h) {
        v.clip.w, v.clip.h = .{ w, h };
        v.tex.refreshCoords();
    }

    gl.BindTexture(gl.TEXTURE_2D, v.tex.id);

    if (pitch != v.pitch) {
        v.pitch = @intCast(pitch);
        gl.PixelStorei(gl.UNPACK_ROW_LENGTH, @intCast(v.pitch / v.bpp));
    }

    if (maybe_data) |data|
        gl.TexSubImage2D(
            gl.TEXTURE_2D,
            0,
            0,
            0,
            @intCast(width),
            @intCast(height),
            v.pix.type,
            v.pix.fmt,
            data,
        );
}

pub fn render() void {
    gl.BindTexture(gl.TEXTURE_2D, v.tex.id);

    gl.EnableClientState(gl.VERTEX_ARRAY);
    gl.EnableClientState(gl.TEXTURE_COORD_ARRAY);

    gl.VertexPointer(2, gl.FLOAT, 0, &v.vertices);
    gl.TexCoordPointer(2, gl.FLOAT, 0, &v.tex.coords);

    gl.DrawArrays(gl.TRIANGLE_STRIP, 0, 4);
}
