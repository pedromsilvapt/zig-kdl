const std = @import("std");
const ArrayList = std.ArrayList;
const StringHashMap = std.StringHashMap;
const Allocator = std.mem.Allocator;

/// Generates the individual test cases for all the files in the test_suite folder
/// If a file exists with the same name both in the input folder as well as
/// the expected_kdl folder, then generates a happy path test case.
/// If the file exists only in the input folder, generates a fail path test case.
/// Happy path are inputs that are expected to be valid and parseable, and their output should match
/// that of the expeected_kdl folder.
/// Fail path are inputs that should be invalid, and for which the parsing API should return an error.
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    const test_cases = try readTestSuite(allocator, "./src/test_suite/input", "./src/test_suite/expected_kdl");
    defer {
        for (test_cases.items) |item| item.deinit(allocator);
        test_cases.deinit();
    }

    var output_file = try std.fs.cwd().createFile("./src/test_suite.zig", .{});
    defer output_file.close();

    try output_file.writeAll(
        \\const std = @import("std");
        \\const helpers = @import("./test_suite_helpers.zig");
        \\
        \\
        \\
    );

    for (test_cases.items) |test_case| {
        std.log.info("Scanned test case {s}, output exists {any}.", .{test_case.name, test_case.output_path != null});

        const rel_input_path = try std.fs.path.relativePosix(allocator, "./src/", test_case.input_path);
        defer allocator.free(rel_input_path);

        std.mem.replaceScalar(u8, rel_input_path, '\\', '/');

        if (test_case.output_path) |output_path| {
            const rel_output_path = try std.fs.path.relativePosix(allocator, "./src/", output_path);
            defer allocator.free(rel_output_path);

            std.mem.replaceScalar(u8, rel_output_path, '\\', '/');

            try output_file.writer().print(
                \\test "TestSuite HappyPath: {s}." {{
                \\    const allocator = std.testing.allocator;
                \\    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./{s}"), @embedFile("./{s}"));
                \\}}
                \\
                \\
                , .{ test_case.name, rel_input_path, rel_output_path });
        } else {
            try output_file.writer().print(
                \\test "TestSuite FailPath: {s}." {{
                \\    const allocator = std.testing.allocator;
                \\    try helpers.testSuiteFailTestCase(allocator, @embedFile("./{s}"));
                \\}}
                \\
                \\
                , .{ test_case.name, rel_input_path });
        }
    }
}

const TestCase = struct {
    name: []const u8,
    input_path: []const u8,
    output_path: ?[]const u8,

    pub fn init(allocator: Allocator, input_folder: []const u8, output_folder: []const u8, file_name: []const u8, output_exists: bool) !TestCase {
        var name = try allocator.dupe(u8, std.fs.path.stem(file_name));
        errdefer allocator.free(name);

        var input_path = try std.fs.path.join(allocator, &.{ input_folder, file_name });
        errdefer allocator.free(input_path);

        var output_path: ?[]const u8 = null;
        errdefer if (output_path) |output_path_str| allocator.free(output_path_str);

        if (output_exists) {
            output_path = try std.fs.path.join(allocator, &.{ output_folder, file_name });
        }

        return TestCase{
            .name = name,
            .input_path = input_path,
            .output_path = output_path,
        };
    }

    pub fn deinit(self: *const TestCase, allocator: Allocator) void {
        allocator.free(self.name);
        allocator.free(self.input_path);

        if (self.output_path) |output_path| {
            allocator.free(output_path);
        }
    }
};

fn readTestSuite(allocator: Allocator, input_folder: []const u8, output_folder: []const u8) !ArrayList(TestCase) {
    var test_cases = ArrayList(TestCase).init(allocator);
    errdefer {
        for (test_cases.items) |item| item.deinit(allocator);

        test_cases.deinit();
    }

    var output_dir_handle = try std.fs.cwd().openDir(output_folder, .{});
    defer output_dir_handle.close();

    var children = try std.fs.cwd().openIterableDir(input_folder, .{});
    defer children.close();

    // use the returned iterator to iterate over dir contents
    var iter = children.iterate();

    while (try iter.next()) |child| {
        if (child.kind == .file) {
            const extension = std.fs.path.extension(child.name);

            if (std.mem.eql(u8, extension, ".kdl")) {
                var output_exists = try fileExists(output_dir_handle, child.name);

                var test_case = try TestCase.init(allocator, input_folder, output_folder, child.name, output_exists);
                errdefer test_case.deinit(allocator);

                try test_cases.append(test_case);
            }
        }
    }

    return test_cases;
}

fn fileExists(dir: std.fs.Dir, sub_path: []const u8) !bool {
    // We assume the file exists unless the access fails with a FileNotFound error code
    var exists = true;

    try (dir.access(sub_path, .{}) catch |e| switch (e) {
        error.FileNotFound => {
            exists = false;
        },
        else => e,
    });

    return exists;

}
