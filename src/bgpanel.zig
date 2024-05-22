const std = @import("std");
const Allocator = std.mem.Allocator;
const Arena = std.heap.ArenaAllocator;
const SDL = @import("sdl2");
const comp = @import("component.zig");
const Size = comp.Size;
const Component = comp.Component;
const Self = Component(State);

pub const State = struct {
    pub const Style = struct {
        margin: [4]usize = .{ 0, 0, 0, 0 },
        padding: [4]usize = .{ 0, 0, 0, 0 },
        col: SDL.Color = .{ .a = 255, .r = 255, .g = 255, .b = 255 },
    };

    arena: Arena,

    child: ?*Component(anyopaque),
    style: Style,

    pub fn setChild(self: *State, child: anytype) void {
        const oldchild = self.child;
        if (oldchild) |ochild| {
            ochild.deinit();
        }

        self.child = child.as(anyopaque);
    }

    pub fn createChild(self: *State, f: anytype, args: anytype) !void {
        self.setChild(try @call(
            .auto,
            f,
            .{self.arena.allocator()} ++ args,
        ));
    }
};

fn sizeFn(self: *const Self, parentSize: Size) !Size {
    return .{
        parentSize[0] - self.state.style.margin[1] - self.state.style.margin[3],
        parentSize[1] - self.state.style.margin[0] - self.state.style.margin[2],
    };
}

fn drawFn(self: *Self, pos: Size, parentSize: Size, renderer: SDL.Renderer) !void {
    const state = self.state;
    const currsize = try self.size(parentSize);
    const spaceForChild = .{
        currsize[0] - self.state.style.padding[1] - self.state.style.padding[3],
        currsize[1] - self.state.style.padding[0] - self.state.style.padding[2],
    };

    if (self.state.child) |child| {
        std.log.debug("5\n", .{});
        try @constCast(&child).*.draw(.{
            pos[0] + self.state.style.margin[1] + self.state.style.padding[1],
            pos[1] + self.state.style.margin[0] + self.state.style.padding[0],
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
    try surf.fillRect(null, state.style.col);

    if (self.state.child) |child| {
        const child_size = try child.*.size(spaceForChild);
        var childrect = .{
            .x = @as(c_int, @intCast(pos[0] + self.state.style.margin[1] + self.state.style.padding[1])),
            .y = @as(c_int, @intCast(pos[1] + self.state.style.margin[0] + self.state.style.padding[0])),
            .width = @as(c_int, @intCast(child_size[0])),
            .height = @as(c_int, @intCast(child_size[1])),
        };
        try surf.fillRect(
            &childrect,
            .{ .a = 0, .r = 0, .g = 0, .b = 0 },
        );
    }

    const rect = .{
        .x = @as(c_int, @intCast(pos[0] + self.state.style.margin[1])),
        .y = @as(c_int, @intCast(pos[1] + self.state.style.margin[0])),
        .width = @as(c_int, @intCast(currsize[0])),
        .height = @as(c_int, @intCast(currsize[1])),
    };
    const tex = try SDL.createTextureFromSurface(renderer, surf);
    defer tex.destroy();
    try renderer.copy(tex, rect, null);
}

fn deinitFn(self: *Self) void {
    if (self.state.child) |child| {
        @constCast(&child).*.deinit();
    }

    self.state.arena.deinit();
}

pub fn init(alloc: Allocator, style: State.Style) !*Self {
    var arena = Arena.init(alloc);

    const state = try arena.allocator().create(State);
    state.* = .{
        .arena = arena,
        .style = style,
        .child = null,
    };

    const ret = try arena.allocator().create(Self);
    ret.* = .{
        .state = state,
        .sizeFn = sizeFn,
        .drawFn = drawFn,
        .deinitFn = deinitFn,
    };

    return ret;
}
