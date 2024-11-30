pub fn poll() callconv(.C) void {}

pub fn state(port: c_uint, device: c_uint, index: c_uint, id: c_uint) callconv(.C) i16 {
    _ = .{ port, device, index, id };
    return undefined;
}
