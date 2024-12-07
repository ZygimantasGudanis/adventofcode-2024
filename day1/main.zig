const std = @import("std");

const print = std.debug.print;

pub fn main() !void {
    var buffer: [1024]u8 = undefined;
    print("Hello world\n", .{});
    const file = try std.fs.openFileAbsolute("/home/dogekun/projects/adventofcode/day1/input.txt", .{});
    const reader = file.reader();
    defer file.close();

    var heapAllocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer heapAllocator.deinit();
    const alloc = heapAllocator.allocator();

    var leftList = std.ArrayList(i32).init(alloc);
    defer leftList.deinit();
    var rightList = std.ArrayList(i32).init(alloc);
    defer rightList.deinit();
    while (true) {
        const line = reader.readUntilDelimiter(&buffer, '\n') catch |err| switch (err) {
            error.EndOfStream => break,
            else => return err,
        };
        if (line.len == 0) continue;
        var tokenizer = std.mem.tokenizeAny(u8, line[0..], " ");
        var val = tokenizer.next().?;
        var parsedVal = try std.fmt.parseInt(i32, val, 0);
        try leftList.append(parsedVal);
        val = tokenizer.next().?;
        parsedVal = try std.fmt.parseInt(i32, val, 0);
        try rightList.append(parsedVal);
    }
    const leftArray = try leftList.toOwnedSlice();
    const rightArray = try rightList.toOwnedSlice();

    std.mem.sort(i32, leftArray, {}, std.sort.asc(i32));
    std.mem.sort(i32, rightArray, {}, std.sort.asc(i32));
    var totalDistance: i32 = 0;
    for (leftArray, rightArray) |left, right| {
        if (left > right) totalDistance += left - right else totalDistance -= left - right;
    }

    print("Total distance = {}\n", .{totalDistance});
}

