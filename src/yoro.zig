const std = @import("std");
const Allocator = std.mem.Allocator;
const Arena = std.heap.ArenaAllocator;
const GPA = std.heap.GeneralPurposeAllocator(.{});
const SDL = @import("sdl2");
const YoroState = @import("state.zig");
const BgPanel = @import("bgpanel.zig");

pub const YoroError = error{
    Exit,
    NotInitialized,
};
pub const Exit = error.Exit;

var state: YoroState = undefined;

pub fn init(main: fn () anyerror!void, flags: struct {
    title: [:0]const u8 = "Yoro App",
    width: usize = 800,
    height: usize = 600,
}) !void {
    if (state.getInited()) {
        return;
    }
    state.setInited(true);

    var gpa = GPA{};
    state.arena = Arena.init(gpa.allocator());
    const baseComp = try BgPanel.init(state.arena.allocator(), .{ .col = .{
        .a = 255,
        .r = 255,
        .g = 255,
        .b = 0,
    }, .margin = .{ 20, 40, 60, 80 }, .padding = .{ 40, 40, 40, 40 } });

    //try baseComp.createChild(BgPanel.init, .{.{ .col = .{
    //    .a = 255,
    //    .r = 255,
    //    .g = 255,
    //    .b = 0,
    //} }});

    state.baseComponent = baseComp.component;

    defer {
        state.lock();
        state.baseComponent.deinit();
        state.arena.deinit();
        state.unlock();
    }

    try SDL.init(.{
        .video = true,
        .events = true,
        .audio = true,
    });
    defer SDL.quit();

    var window = try SDL.createWindow(
        flags.title,
        .{ .centered = {} },
        .{ .centered = {} },
        flags.width,
        flags.height,
        .{ .vis = .shown, .resizable = true },
    );
    defer window.destroy();

    var renderer = try SDL.createRenderer(window, null, .{ .accelerated = true });
    defer renderer.destroy();

    var mainThread = try std.Thread.spawn(.{}, main, .{});
    loop: while (true) {
        while (SDL.pollEvent()) |ev| {
            switch (ev) {
                .quit => break :loop,
                else => {},
            }
        }

        try state.baseComponent.draw(.{ 0, 0 }, .{ flags.width, flags.height }, renderer);

        renderer.present();
    }

    mainThread.detach();
    return error.Exit;
}
