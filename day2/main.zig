const std = @import("std");

const print = std.debug.print;

pub fn main() !void {
    const start = std.time.microTimestamp();
    try version1();
    const stop = std.time.microTimestamp();
    print("{} micro seconds\n", .{stop - start});
}

fn version1() !void {
    const file = try std.fs.cwd().openFile("day2/input.txt", .{});
    defer file.close();

    var heapAllocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer heapAllocator.deinit();
    const alloc = heapAllocator.allocator();

    const size_limit = std.math.maxInt(u32); // or any other suitable limit
    const result = try file.readToEndAlloc(alloc, size_limit);
    defer alloc.free(result);

    var leftList = std.ArrayList([]const u8).init(alloc);
    defer leftList.deinit();
    var rightList = std.ArrayList([]const u8).init(alloc);
    defer rightList.deinit();
    var tokenizer = std.mem.tokenizeAny(u8, result, " \n");
    var isLeft = true;
    while (tokenizer.next()) |val| {
        if (isLeft) {
            try leftList.append(try alloc.dupe(u8, val));
        } else {
            try rightList.append(try alloc.dupe(u8, val));
        }
        isLeft = !isLeft;
    }
    var rightHashMap = std.HashMap(i32, i32, IntegerContext, std.hash_map.default_max_load_percentage).init(alloc);
    defer rightHashMap.deinit();
    var leftHashMap = std.HashMap(i32, i32, IntegerContext, std.hash_map.default_max_load_percentage).init(alloc);
    defer leftHashMap.deinit();
    {
        const handle1 = try std.Thread.spawn(.{}, parseAndMap, .{ &rightHashMap, &rightList.items });
        defer handle1.join();
        const handle2 = try std.Thread.spawn(.{}, parseAndMap, .{ &leftHashMap, &leftList.items });
        defer handle2.join();
    }
    var real_path: i32 = 0;
    var leftIterator = leftHashMap.iterator();
    while (leftIterator.next()) |item| {
        const rightItem = rightHashMap.get(item.key_ptr.*);
        if (rightItem == null) continue;

        real_path += item.key_ptr.* * item.value_ptr.* * rightItem.?;
    } else {}
    print("{any}\n", .{real_path});
}

const IntegerContext = struct {
    pub fn hash(_: IntegerContext, s: i32) u64 {
        return @as(u32, @bitCast(s));
    }

    pub fn eql(_: IntegerContext, a: i32, b: i32) bool {
        return a == b;
    }
};

pub fn parseAndMap(
    hashmap: *std.hash_map.HashMap(i32, i32, IntegerContext, std.hash_map.default_max_load_percentage),
    raw_values: *[][]const u8,
) !void {
    for (raw_values.*) |raw_value| {
        const parsedVal = try std.fmt.parseInt(i32, raw_value, 0);
        const entry = hashmap.getEntry(parsedVal);
        if (entry != null) {
            entry.?.value_ptr.* += 1;
        } else try hashmap.put(parsedVal, 1);
    }
}
