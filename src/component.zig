const std = @import("std");
const Tuple = std.meta.Tuple;
const Allocator = std.mem.Allocator;
const SDL = @import("sdl2");

const Self = @This();

pub const Size = Tuple(&.{ usize, usize });

state: *anyopaque,
sizeFn: *const fn (*anyopaque, Size) anyerror!Size,
drawFn: *const fn (*anyopaque, Size, Size, SDL.Renderer) anyerror!void,
deinitFn: *const fn (*anyopaque) void,

pub fn size(self: *const Self, parentsize: Size) !Size {
    return self.sizeFn(self.state, parentsize);
}

pub fn draw(self: *Self, pos: Size, parentSize: Size, renderer: SDL.Renderer) !void {
    try self.drawFn(self.state, pos, parentSize, renderer);
}

pub fn deinit(self: *Self) void {
    self.deinitFn(self.state);
}
