const std = @import("std");
const print = std.debug.print;

pub fn main() !void {
    const start = std.time.nanoTimestamp();
    try version1();
    const stop = std.time.nanoTimestamp();
    print("{} micro seconds\n", .{stop - start});
}

fn version1() !void {
    var arenaAlloc = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arenaAlloc.deinit();
    const alloc = arenaAlloc.allocator();

    const file = try std.fs.cwd().openFile("day2/input.txt", .{});
    defer file.close();

    const size_limit = std.math.maxInt(u32); // or any other suitable limit
    const result = try file.readToEndAlloc(alloc, size_limit);
    defer alloc.free(result);

    var list = std.ArrayList([]const u8).init(alloc);
    defer list.deinit();

    var tokenizer = std.mem.tokenizeAny(u8, result, "\r\n");
    while (tokenizer.next()) |line| {
        try list.append(try alloc.dupe(u8, line[0..]));
    }
    var count: u32 = 0;
    // {
    //     const halfs = list.items.len / 4;
    //     var count1: u32 = 0;
    //     var count2: u32 = 0;
    //     var count3: u32 = 0;
    //     var count4: u32 = 0;
    //     const thread1 = try std.Thread.spawn(.{}, calculate, .{ &arenaAlloc, list.items[0..halfs], &count1 });
    //     defer thread1.join();
    //     const thread2 = try std.Thread.spawn(.{}, calculate, .{ &arenaAlloc, list.items[halfs .. halfs * 2], &count2 });
    //     defer thread2.join();
    //     const thread3 = try std.Thread.spawn(.{}, calculate, .{ &arenaAlloc, list.items[halfs * 2 .. halfs * 3], &count3 });
    //     defer thread3.join();
    //     const thread4 = try std.Thread.spawn(.{}, calculate, .{ &arenaAlloc, list.items[halfs * 3 ..], &count4 });
    //     defer thread4.join();
    //     try calculate(&arenaAlloc, list.items, &count);

    //     defer count = count1 + count2 + count3 + count4;
    // }
    try calculate2(&arenaAlloc, list.items[0..], &count);
    print("Count = {}\n", .{count});
}

fn calculate(arenaAlloc: *std.heap.ArenaAllocator, data: [][]const u8, count: *u32) !void {
    const alloc = arenaAlloc.allocator();
    var buffer = std.ArrayList(i32).init(alloc);
    defer buffer.deinit();

    for (data) |line| {
        var tokenizer = std.mem.tokenizeAny(u8, line, " ");
        while (tokenizer.next()) |val| {
            try buffer.append(try std.fmt.parseInt(i32, val, 0));
        }
        if (validateValues(buffer.items[0..])) {
            count.* += 1;
        }
        buffer.clearRetainingCapacity();
    }
}

fn validateValues(list: []i32) bool {
    // print("{}, {}\n", .{ val1, val2 });
    const increasing = list[0] < list[1];
    for (1..(list.len - 1)) |i| {
        const val1 = list[i] - list[i - 1];
        const val2 = list[i + 1] - list[i];
        if ((increasing and (val1 < 0 or val2 < 0)) or (!increasing and (val1 > 0 or val2 > 0)))
            return false;
        if (val1 == 0 or val1 < -3 or val1 > 3)
            return false;
        if (val2 == 0 or val2 < -3 or val2 > 3)
            return false;
    }
    return true;
}

fn calculate2(arenaAlloc: *std.heap.ArenaAllocator, data: [][]const u8, count: *u32) !void {
    const alloc = arenaAlloc.allocator();
    var buffer = std.ArrayList(i32).init(alloc);
    defer buffer.deinit();

    for (data) |line| {
        var tokenizer = std.mem.tokenizeAny(u8, line, " ");
        while (tokenizer.next()) |val| {
            try buffer.append(try std.fmt.parseInt(i32, val, 0));
        }
        const result = validateValues2(buffer.items[0..]);
        if (result.success) {
            count.* += 1;
        } else if (result.issues != null) {
            var temp = std.ArrayList(i32).init(alloc);
            defer temp.deinit();
            for (result.issues.?) |issue| {
                var retry: validationResult = undefined;
                if (issue == 0) {
                    retry = validateValues2(buffer.items[1..]);
                } else if (issue == line.len - 1) {
                    retry = validateValues2(buffer.items[0 .. line.len - 1]);
                } else {
                    // print("{any}\n", .{buffer.items});
                    // print("Any {any}\n", .{issue});
                    for (buffer.items[0..issue]) |buff| {
                        try temp.append(buff);
                    }
                    for (buffer.items[issue + 1 ..]) |buff| {
                        // print("Any {any}\n", .{buff});
                        try temp.append(buff);
                    }
                    //try temp.appendSlice(buffer.items[issue + 1 ..]);
                    retry = validateValues2(temp.items[0..]);
                }

                if (retry.success) {
                    count.* += 1;
                    break;
                }
                temp.clearRetainingCapacity();
            }
        }
        buffer.clearRetainingCapacity();
    }
}

// I hate this
fn validateValues2(list: []i32) validationResult {
    // print("{}, {}\n", .{ val1, val2 });
    const increasing = list[0] < list[1];
    for (1..(list.len - 1)) |i| {
        const val1 = list[i] - list[i - 1];
        const val2 = list[i + 1] - list[i];
        if ((increasing and (val1 < 0 or val2 < 0)) or (!increasing and (val1 > 0 or val2 > 0))) {
            const index = @as(u32, @intCast(i));
            return validationResult{ .success = false, .issues = [_]u32{ index, index + 1, index - 1 } };
        }
        if (val1 == 0 or val1 < -3 or val1 > 3) {
            const index = @as(u32, @intCast(i));
            return validationResult{ .success = false, .issues = [_]u32{ index, index + 1, index - 1 } };
        }
        if (val2 == 0 or val2 < -3 or val2 > 3) {
            const index = @as(u32, @intCast(i));
            return validationResult{ .success = false, .issues = [_]u32{ index, index + 1, index - 1 } };
        }
    }
    return validationResult{ .success = true };
}

const validationResult = struct { success: bool, issues: ?[3]u32 = null };
