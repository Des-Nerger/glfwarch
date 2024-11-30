const std = @import("std");
const zigglgen = @import("zigglgen");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const exe = b.addExecutable(.{
        .name = "glfwarch",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = b.standardOptimizeOption(.{}),
    });
    exe.linkLibC();
    exe.addIncludePath(b.path("include"));
    if (target.query.isNativeOs() and target.result.os.tag != .windows) {
        exe.linkSystemLibrary("glfw");
        // exe.linkSystemLibrary("openal");
    } else inline for (.{
        .{ .name = "glfw", .artifact = "glfw" },
        // .{.name = "openal", .artifact = ""},
    }) |dep|
        exe.linkLibrary(b.lazyDependency(dep.name, .{
            .optimize = .ReleaseFast,
            .target = target,
            // .preferred_link_mode = .shared,
        }).?.artifact(dep.artifact));
    exe.root_module.addImport("gl", zigglgen.generateBindingsModule(
        b,
        zigglgen.GeneratorOptions{
            .api = .gl,
            .version = .@"2.0",
            .extensions = &.{.ARB_framebuffer_object},
        },
    ));

    const run_cmd = b.addRunArtifact(exe);
    if (b.args) |args|
        run_cmd.addArgs(args);
    b.step("run", "Run the app").dependOn(&run_cmd.step);

    const install_step = b.getInstallStep();
    run_cmd.step.dependOn(install_step);
    install_step.dependOn(&b.addInstallArtifact(exe, .{ .dest_dir = .{ .override = .prefix } }).step);
}
