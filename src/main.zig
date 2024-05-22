const yoro = @import("yoro.zig");

pub fn main() !void {
    yoro.init(main, .{
        .title = "Yoro Example App",
        .width = 640,
        .height = 480,
    }) catch |e| switch (e) {
        yoro.Exit => return,
        else => return e,
    };

    while (true) {}
}
