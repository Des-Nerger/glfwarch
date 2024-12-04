const c = @import("c.zig");
const g = @import("globals.zig");
const in = @This();
const meta = @import("meta.zig");

pub fn poll() callconv(.C) void {
    for (&in.binds) |*bind|
        in.joy[bind.rk] = if (c.glfwGetKey(g.v.win, bind.k) == c.GLFW_PRESS) 1 else 0;

    // Quit glfwarch when pressing the Escape key.
    if (c.glfwGetKey(g.v.win, c.GLFW_KEY_ESCAPE) == c.GLFW_PRESS)
        c.glfwSetWindowShouldClose(g.v.win, c.GLFW_TRUE);
}

const Keymap = struct {
    k: c_int,
    rk: c_uint,
};

usingnamespace struct {
    pub const binds = meta.arrayOfStructs( // zig fmt: off
        Keymap,
        &.{                     "k",                            "rk" },
        &.{
            .{         c.GLFW_KEY_X,      c.RETRO_DEVICE_ID_JOYPAD_A },
            .{         c.GLFW_KEY_Z,      c.RETRO_DEVICE_ID_JOYPAD_B },
            .{         c.GLFW_KEY_A,      c.RETRO_DEVICE_ID_JOYPAD_Y },
            .{         c.GLFW_KEY_S,      c.RETRO_DEVICE_ID_JOYPAD_X },
            .{         c.GLFW_KEY_Q,      c.RETRO_DEVICE_ID_JOYPAD_L },
            .{         c.GLFW_KEY_W,      c.RETRO_DEVICE_ID_JOYPAD_R },
            .{        c.GLFW_KEY_UP,     c.RETRO_DEVICE_ID_JOYPAD_UP },
            .{      c.GLFW_KEY_DOWN,   c.RETRO_DEVICE_ID_JOYPAD_DOWN },
            .{      c.GLFW_KEY_LEFT,   c.RETRO_DEVICE_ID_JOYPAD_LEFT },
            .{     c.GLFW_KEY_RIGHT,  c.RETRO_DEVICE_ID_JOYPAD_RIGHT },
            .{     c.GLFW_KEY_ENTER,  c.RETRO_DEVICE_ID_JOYPAD_START },
            .{ c.GLFW_KEY_BACKSPACE, c.RETRO_DEVICE_ID_JOYPAD_SELECT },
        },
    );
    // zig fmt: on
    pub var joy = [_]i16{0} ** (c.RETRO_DEVICE_ID_JOYPAD_R3 + 1);
};

pub fn state(port: c_uint, device: c_uint, index: c_uint, id: c_uint) callconv(.C) i16 {
    if (0 != port or 0 != index or device != c.RETRO_DEVICE_JOYPAD)
        return 0;
    return in.joy[id];
}
