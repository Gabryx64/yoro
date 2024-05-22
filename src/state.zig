const std = @import("std");
const RwLock = std.Thread.RwLock;
const Arena = std.heap.ArenaAllocator;
const Component = @import("component.zig").Component;
const Self = @This();

rwlock: RwLock = .{},
inited: bool = false,
arena: Arena,
baseComponent: *Component(anyopaque),

pub fn lock(self: *Self) void {
    self.rwlock.lock();
}

pub fn unlock(self: *Self) void {
    self.rwlock.unlock();
}

pub fn lockShared(self: *Self) void {
    self.rwlock.lockShared();
}

pub fn unlockShared(self: *Self) void {
    self.rwlock.unlockShared();
}

pub fn getInited(self: *Self) bool {
    self.lockShared();
    defer self.unlockShared();
    return self.inited;
}

pub fn setInited(self: *Self, newinited: bool) void {
    self.lock();
    defer self.unlock();
    self.inited = newinited;
}
