const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    //const mode = b.standardReleaseOptions();

    //const exe = b.addExecutable("hello-gamedev", "src/main.zig");
    const exe = b.addExecutable(.{
        .name = "asteroid-shooter",
        // In this case the main source file is merely a path, however, in more
        // complicated build scripts, this could be a generated file.
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = b.standardOptimizeOption(.{}),
    });
    //exe.setTarget(target);
    //exe.setBuildMode(mode);

    const sdl_path = "/opt/homebrew/";
    exe.addIncludePath(sdl_path ++ "include/SDL2");
    exe.addLibraryPath(sdl_path ++ "lib/");
    exe.addIncludePath(sdl_path ++ "");
    //b.installBinFile(sdl_path ++ "lib/x64/SDL2.lib", "SDL2.lib");
    exe.linkSystemLibrary("SDL2");
    exe.linkSystemLibrary("SDL2_image");
    exe.linkLibC();
    exe.install();
}
