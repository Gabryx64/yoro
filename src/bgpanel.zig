const std = @import("std");
const Allocator = std.mem.Allocator;
const Arena = std.heap.ArenaAllocator;
const SDL = @import("sdl2");
const Component = @import("component.zig");
const Size = Component.Size;
const Self = @This();

pub const Style = struct {
    margin: [4]usize = .{ 0, 0, 0, 0 },
    padding: [4]usize = .{ 0, 0, 0, 0 },
    col: SDL.Color = .{ .a = 255, .r = 255, .g = 255, .b = 255 },
};

component: *Component,
rendered: bool = false,
arena: Arena,
child: ?*Component,
style: Style,

pub fn setChild(self: *Self, child: anytype) void {
    const oldchild = self.child;
    if (oldchild) |ochild| {
        ochild.deinit();
    }
    self.child = child.component;
}
pub fn createChild(self: *Self, f: anytype, args: anytype) !void {
    self.setChild(try @call(
        .auto,
        f,
        .{self.arena.allocator()} ++ args,
    ));
}

fn sizeFn(opself: *anyopaque, parentSize: Size) !Size {
    const self: *Self = @ptrCast(@alignCast(opself));
    return .{
        parentSize[0] - self.style.margin[1] - self.style.margin[3],
        parentSize[1] - self.style.margin[0] - self.style.margin[2],
    };
}

fn drawFn(opself: *anyopaque, pos: Size, parentSize: Size, renderer: SDL.Renderer) !void {
    const self: *Self = @ptrCast(@alignCast(opself));
    const currsize = try sizeFn(opself, parentSize);
    const spaceForChild = .{
        currsize[0] - self.style.padding[1] - self.style.padding[3],
        currsize[1] - self.style.padding[0] - self.style.padding[2],
    };

    if (self.child) |child| {
        std.log.debug("5\n", .{});
        try @constCast(&child).*.draw(.{
            pos[0] + self.style.margin[1] + self.style.padding[1],
            pos[1] + self.style.margin[0] + self.style.padding[0],
        }, spaceForChild, renderer);
    }

    if (self.rendered) {
        return;
    }
    defer self.rendered = true;

    var surf = try SDL.createRgbSurfaceWithFormat(
        @intCast(currsize[0]),
        @intCast(currsize[1]),
        .argb8888,
    );
    defer surf.destroy();
    try surf.fillRect(null, self.style.col);

    if (self.child) |child| {
        const child_size = try child.*.size(spaceForChild);
        var childrect = .{
            .x = @as(c_int, @intCast(pos[0] + self.style.margin[1] + self.style.padding[1])),
            .y = @as(c_int, @intCast(pos[1] + self.style.margin[0] + self.style.padding[0])),
            .width = @as(c_int, @intCast(child_size[0])),
            .height = @as(c_int, @intCast(child_size[1])),
        };
        try surf.fillRect(
            &childrect,
            .{ .a = 0, .r = 0, .g = 0, .b = 0 },
        );
    }

    const rect = .{
        .x = @as(c_int, @intCast(pos[0] + self.style.margin[1])),
        .y = @as(c_int, @intCast(pos[1] + self.style.margin[0])),
        .width = @as(c_int, @intCast(currsize[0])),
        .height = @as(c_int, @intCast(currsize[1])),
    };
    const tex = try SDL.createTextureFromSurface(renderer, surf);
    defer tex.destroy();
    try renderer.copy(tex, rect, null);
}

fn deinitFn(opself: *anyopaque) void {
    const self = @as(*Self, @ptrCast(@alignCast(opself)));
    if (self.child) |child| {
        @constCast(&child).*.deinit();
    }

    self.arena.deinit();
}

pub fn init(alloc: Allocator, style: Style) !*Self {
    var arena = Arena.init(alloc);

    const self = try arena.allocator().create(Self);
    self.* = .{
        .arena = arena,
        .style = style,
        .child = null,
        .component = undefined,
    };

    const comp = try arena.allocator().create(Component);
    comp.* = .{
        .state = self,
        .sizeFn = sizeFn,
        .drawFn = drawFn,
        .deinitFn = deinitFn,
    };
    self.component = comp;

    return self;
}
