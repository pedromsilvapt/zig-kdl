const std = @import("std");

pub fn build(b: *std.Build) void {
    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    _ = b.addModule("kdl", .{
        .source_file = .{ .path = "src/main.zig" },
        .dependencies = &[_]std.Build.ModuleDependency{},
    });

    const lib = b.addStaticLibrary(.{
        .name = "zig-kdl",
        .root_source_file = .{ .path = "./src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    _ = b.addInstallArtifact(lib, .{});

    const main_tests = b.addTest(.{
        .name = "zig-kdl-tests",
        .root_source_file = .{ .path = "./src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const run_test = b.addRunArtifact(main_tests);
    run_test.has_side_effects = true;
    if (b.args) |args| {
        run_test.addArgs(args);
    }

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&run_test.step);
}
