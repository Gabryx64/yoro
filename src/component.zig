const std = @import("std");
const Tuple = std.meta.Tuple;
const Allocator = std.mem.Allocator;
const SDL = @import("sdl2");

pub const Size = Tuple(&.{ usize, usize });

pub fn Component(comptime S: type) type {
    return packed struct {
        const Self = @This();

        rendered: bool = false,
        state: *S,
        sizeFn: *const fn (*const Self, Size) anyerror!Size,
        drawFn: *const fn (*Self, Size, Size, SDL.Renderer) anyerror!void,
        deinitFn: *const fn (*Self) void,

        pub fn size(self: *const Self, parentsize: Size) !Size {
            return self.sizeFn(self, parentsize);
        }

        pub fn draw(self: *Self, pos: Size, parentSize: Size, renderer: SDL.Renderer) !void {
            try self.drawFn(self, pos, parentSize, renderer);
        }

        pub fn deinit(self: *Self) void {
            self.deinitFn(self);
        }

        pub fn as(self: *const Self, comptime T: type) *Component(T) {
            return @as(*Component(T), @constCast(@ptrCast(@alignCast(self))));
        }
    };
}
