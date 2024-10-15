pub fn init(sample_rate: f64) !void {
    _ = sample_rate;
}

pub fn deinit() void {}

pub fn sample(left: i16, right: i16) callconv(.C) void {
    _, _ = .{ left, right };
}

pub fn sampleBatch(data: [*c]const i16, frames: usize) callconv(.C) usize {
    _, _ = .{ data, frames };
    return undefined;
}
