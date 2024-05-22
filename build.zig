const std = @import("std");
const Sdk = @import("SDL.zig/build.zig");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});

    const sdk = Sdk.init(b, null);

    const yoro = b.addExecutable(.{
        .name = "yoro-example",
        .root_source_file = .{ .cwd_relative = "src/main.zig" },
        .target = target,
    });
    sdk.link(yoro, .dynamic);

    yoro.root_module.addImport("sdl2", sdk.getWrapperModule());
    b.installArtifact(yoro);
}
