const std = @import("std");
const Token = @import("./tokens.zig").Token;
const Element = @import("./parser.zig").Element;
const Allocator = std.mem.Allocator;

pub fn Printer(comptime Writer: type) type {
    return struct {
        const Self = @This();

        writer: Writer,
        ident: []const u8 = "\t",
        newline: []const u8 = "\n",
        _last_element: std.meta.Tag(Element) = .node_end,
        _depth: i32 = 0,
        _has_children: bool = false,

        pub fn init(writer: Writer) Self {
            return .{
                .writer = writer,
            };
        }

        fn writeIndent(self: *Self, offset: i32) !void {
            if (offset < 0 and offset * -1 > self._depth) return error.InvalidNodeDepth;

            const depth: usize = @intCast(self._depth + offset);

            // Indent the current node
            for (0..depth) |_| {
                try self.writer.writeAll(self.ident);
            }
        }

        fn writeValue(self: *Self, value: Element.Value) !void {
            // TODO Type name
            try self.writeToken(value.data);
        }

        fn writeToken(self: *Self, token: Token) !void {
            try self.writer.writeAll(token.text);
        }

        pub fn printElement(self: *Self, element: Element) !void {
            switch (element) {
                .node_begin => |node|  {
                    if (self._depth > 0 and self._has_children == false) {
                        // If we are beginning a node that is not the root node, then
                        // we must open curly braces to indicate child nodes
                        try self.writer.writeAll(" {");
                        try self.writer.writeAll(self.newline);
                    }

                    // Indent the current node
                    try self.writeIndent(0);

                    // TODO Type name

                    // Write the node name
                    try self.writeToken(node.name);

                    // Increase the depth after writing the name of the node
                    // This will be the depth of it's children
                    self._depth += 1;

                    // When a node begins, it always begins as having no children
                    self._has_children = false;

                    self._last_element = .node_begin;
                },
                .node_end => {
                    if (self._depth <= 0) return error.InvalidNodeDepth;

                    if (self._last_element != .node_end) {
                        try self.writer.writeAll(self.newline);
                    }

                    self._depth -= 1;

                    // Only if this node had children, will we want to close it with curly braces
                    if (self._has_children) {
                        try self.writeIndent(0);
                        try self.writer.writeAll("}");
                        try self.writer.writeAll(self.newline);
                    }

                    // If we are ending a node, then it's parent had children (the node we just ended)
                    // So this should ALWAYS be true after a node ends
                    self._has_children = true;

                    self._last_element = .node_end;
                },
                .property => |prop| {
                    try self.writer.writeAll(" ");
                    try self.writeToken(prop.name);
                    try self.writer.writeAll("=");
                    try self.writeValue(prop.value);
                },
                .argument => |value| {
                    try self.writer.writeAll(" ");
                    try self.writeValue(value);
                },
            }
        }

        pub fn printNodeBegin(self: *Self, name: []const u8, type_name: ?[]const u8) !void {
            const name_token = Token { .kind = .bare_identifier, .text = name };
            const type_token = if (type_name) |str|
                Token { .kind = .bare_identifier, .text = str }
            else
                null;

            try self.printElement(.{
                .node_begin = .{
                    .name = name_token,
                    .type_name = type_token,
                }
            });
        }

        pub fn printNodeEnd(self: *Self) !void {
            try self.printElement(.{
                .node_end = {}
            });
        }

        pub fn printProperty(self: *Self, allocator: Allocator, name: []const u8, value: Token.Scalar, type_name: ?[]const u8) !void {
            const name_token = Token { .kind = .bare_identifier, .text = name };

            var value_token = try Token.fromScalar(allocator, value);
            defer value_token.deinitFromScalar(allocator);

            const type_token = if (type_name) |str|
                Token { .kind = .bare_identifier, .text = str }
            else
                null;

            try self.printElement(.{
                .property = .{
                    .name = name_token,
                    .value = .{
                        .type_name = type_token,
                        .data = value_token,
                    }
                }
            });
        }

        pub fn printArgument(self: *Self, allocator: Allocator, value: Token.Scalar, type_name: ?[]const u8) !void {
            var value_token = try Token.fromScalar(allocator, value);
            defer value_token.deinitFromScalar(allocator);

            const type_token = if (type_name) |str|
                Token { .kind = .bare_identifier, .text = str }
            else
                null;

            try self.printElement(.{
                .argument = .{
                    .type_name = type_token,
                    .data = value_token,
                }
            });
        }
    };
}

test "Single root node" {
    var allocator = std.testing.allocator;
    var buffer = std.ArrayList(u8).init(allocator);
    defer buffer.deinit();
    const BufferWriter = @TypeOf(buffer.writer());

    var printer = Printer(BufferWriter).init(buffer.writer());

    try printer.printNodeBegin("root", null);
    try printer.printProperty(allocator, "prop", .{ .string = "test" }, null);
    try printer.printArgument(allocator, .{ .integer = 2 }, null);
    try printer.printNodeEnd();

    var result = try buffer.toOwnedSlice();
    defer allocator.free(result);

    try std.testing.expectEqualStrings("root prop=\"test\" 2\n", result);
}

test "Child nodes" {
    var allocator = std.testing.allocator;
    var buffer = std.ArrayList(u8).init(allocator);
    defer buffer.deinit();
    const BufferWriter = @TypeOf(buffer.writer());

    var printer = Printer(BufferWriter).init(buffer.writer());
    printer.ident = "  ";

    try printer.printNodeBegin("package", null);
    try printer.printProperty(allocator, "prop", .{ .string = "test" }, null);
    try printer.printArgument(allocator, .{ .integer = 2 }, null);

    try printer.printNodeBegin("childless", null);
    try printer.printNodeEnd();

    try printer.printNodeBegin("child", null);
    try printer.printNodeBegin("childs-child", null);
    try printer.printNodeEnd();
    try printer.printNodeEnd();

    try printer.printNodeBegin("childless", null);
    try printer.printNodeEnd();

    try printer.printNodeBegin("child", null);
    try printer.printNodeBegin("childs-child", null);
    try printer.printNodeEnd();
    try printer.printNodeEnd();

    try printer.printNodeEnd();

    var result = try buffer.toOwnedSlice();
    defer allocator.free(result);

    try std.testing.expectEqualStrings(
        \\package prop="test" 2 {
        \\  childless
        \\  child {
        \\    childs-child
        \\  }
        \\  childless
        \\  child {
        \\    childs-child
        \\  }
        \\}
        \\
        ,
        result
    );
}
