const std = @import("std");
const Allocator = std.mem.Allocator;
const Parser = @import("./parser.zig").Parser;
const OpinionatedPrinter = @import("./printer.zig").OpinionatedPrinter;

const VERBOSE_DEBUG = false;

pub fn testSuiteHappyTestCase(allocator: Allocator, comptime expected_input: []const u8, comptime expected_output: []const u8) !void {
    var output_buffer = std.ArrayList(u8).init(allocator);
    defer output_buffer.deinit();

    const BufferWriter = @TypeOf(output_buffer.writer());
    var printer = OpinionatedPrinter(BufferWriter).init(allocator, output_buffer.writer());
    defer printer.deinit();

    var parser = try Parser.init(expected_input);
    parser.debug = VERBOSE_DEBUG;

    while (try parser.next()) |element| {
        try printer.printElement(element);
    }
    try printer.printEndOfFile();

    var output = try output_buffer.toOwnedSlice();
    defer allocator.free(output);

    try std.testing.expectEqualStrings(expected_output, output);
}

pub fn testSuiteFailTestCase(allocator: Allocator, expected_input: []const u8) !void {
    var output_buffer = std.ArrayList(u8).init(allocator);
    defer output_buffer.deinit();

    var parser = try Parser.init(expected_input);
    parser.debug = VERBOSE_DEBUG;

    var failed = false;

    while (true) {
        const element = parser.next() catch {
            failed = true;
            break;
        };
        if (element == null) {
            break;
        }
    }

    try std.testing.expect(failed);
}
