const std = @import("std");
const Token = @import("./tokens.zig").Token;
const Element = @import("./parser.zig").Element;
const ElementOwned = @import("./parser.zig").ElementOwned;
const Allocator = std.mem.Allocator;

pub fn Printer(comptime Writer: type) type {
    return struct {
        const Self = @This();

        allocator: Allocator,
        writer: Writer,
        ident: []const u8 = "    ",
        newline: []const u8 = "\n",
        _last_element: std.meta.Tag(Element) = .node_end,
        _depth: i32 = 0,
        _has_children: bool = false,
        _empty: bool = true,

        pub fn init(allocator: Allocator, writer: Writer) Self {
            return .{
                .allocator = allocator,
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

        fn writeValue(self: *Self, data: Token.Scalar, type_name: ?[]const u8) !void {
            if (type_name) |type_name_str| {
                try self.writeTypeAnnotation(type_name_str);
            }

            try self.writeScalar(data);
        }

        fn writeScalar(self: *Self, scalar: Token.Scalar) !void {
            var token = try Token.fromScalar(self.allocator, scalar);
            defer token.deinitFromScalar(self.allocator);

            try self.writer.writeAll(token.text);
        }

        fn writeIdentifier(self: *Self, identifier: []const u8) !void {
            var token = try Token.fromIdentifier(self.allocator, identifier);
            defer token.deinitFromScalar(self.allocator);

            try self.writer.writeAll(token.text);
        }

        fn writeTypeAnnotation(self: *Self, type_name: []const u8) !void {
            try self.writer.writeAll("(");
            try self.writeIdentifier(type_name);
            try self.writer.writeAll(")");
        }

        pub fn printElement(self: *Self, element: Element) !void {
            var owned_element = try element.toOwned(self.allocator);
            defer owned_element.deinit(self.allocator);

            try self.printElementOwned(owned_element);
        }

        pub fn printElementOwned(self: *Self, element: ElementOwned) !void {
            switch (element) {
                .node_begin => |node| try self.printNodeBegin(node.name, node.type_name),
                .node_end => try self.printNodeEnd(),
                .property => |prop| try self.printProperty(prop.name, prop.value.data, prop.value.type_name),
                .argument => |arg| try self.printArgument(arg.data, arg.type_name),
                .slashdash => try self.printSlashdash(),
            }
        }

        pub fn printNodeBegin(self: *Self, name: []const u8, type_name: ?[]const u8) !void {
            if (self._depth > 0 and self._has_children == false) {
                // If we are beginning a node that is not the root node, then
                // we must open curly braces to indicate child nodes
                try self.writer.writeAll(" {");
                try self.writer.writeAll(self.newline);
            }

            // Indent the current node
            try self.writeIndent(0);

            if (type_name) |type_name_str| {
                try self.writeTypeAnnotation(type_name_str);
            }

            // Write the node name
            try self.writeIdentifier(name);

            // Increase the depth after writing the name of the node
            // This will be the depth of it's children
            self._depth += 1;

            // When a node begins, it always begins as having no children
            self._has_children = false;

            self._last_element = .node_begin;
        }

        pub fn printNodeEnd(self: *Self) !void {
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

            // If no elements are printed, there is an expectation that a newline is still printed
            // Usually node_end prints newlines, so when there is at least one element printed,
            // we don't need to worry about that. This flag is for us to know that we don't need
            // to forcefully print that newline on it's own
            self._empty = false;
        }

        pub fn printProperty(self: *Self, name: []const u8, value: Token.Scalar, type_name: ?[]const u8) !void {
            try self.writer.writeAll(" ");
            try self.writeIdentifier(name);
            try self.writer.writeAll("=");
            try self.writeValue(value, type_name);
        }

        pub fn printArgument(self: *Self, value: Token.Scalar, type_name: ?[]const u8) !void {
            try self.writer.writeAll(" ");
            try self.writeValue(value, type_name);
        }

        pub fn printSlashdash(self: *Self) !void {
            try self.writer.writeAll(" /-");
        }

        pub fn printEndOfFile(self: *Self) !void {
            if (self._empty) {
                try self.writer.writeAll(self.newline);
            }
        }
    };
}

pub fn OpinionatedPrinter(comptime Writer: type) type {
    return struct {
        const Self = @This();

        raw_printer: Printer(Writer),
        properties: std.StringHashMap(ElementOwned.Property),
        arguments: std.ArrayList(ElementOwned.Value),

        pub fn init(allocator: Allocator, writer: Writer) Self {
            return .{
                .raw_printer = Printer(Writer).init(allocator, writer),
                .properties = std.StringHashMap(ElementOwned.Property).init(allocator),
                .arguments = std.ArrayList(ElementOwned.Value).init(allocator),
            };
        }

        pub fn printElement(self: *Self, element: Element) !void {
            // Only free up 'owned' if there is an error inside this function
            // Otherwise, we will transfer ownership of it to 'printElementOwned'
            var owned = try element.toOwned(self.raw_printer.allocator);

            try self.printElementOwned(owned);
        }

        /// When called, receives ownership of 'element'
        pub fn printElementOwned(self: *Self, element: ElementOwned) !void {
            const allocator = self.raw_printer.allocator;

            switch (element) {
                .node_begin => {
                    defer element.deinit(allocator);

                    try self.flushNode();

                    try self.raw_printer.printElementOwned(element);
                },
                .node_end => {
                    try self.flushNode();

                    try self.raw_printer.printElementOwned(element);
                },
                .property => |prop| {
                    errdefer element.deinit(allocator);

                    var result = try self.properties.getOrPut(prop.name);

                    if (result.found_existing) {
                        var previous_element = ElementOwned{ .property = result.value_ptr.* };
                        previous_element.deinit(allocator);
                    }

                    // TODO Should we do this, or keep the old key instead?
                    result.key_ptr.* = prop.name;
                    result.value_ptr.* = prop;
                },
                .argument => |value| {
                    errdefer element.deinit(allocator);

                    try self.arguments.append(value);
                },
                .slashdash => |slashdash| {
                    _ = slashdash;
                    return error.NotYetImplemented;
                },
            }
        }

        pub fn flushNode(self: *Self) !void {
            if (self.properties.count() > 0 or self.arguments.items.len > 0) {
                const allocator = self.raw_printer.allocator;

                // Make sure the memory held by the arguments list is freed no matter what
                defer {
                    for (self.arguments.items) |argument| {
                        var argument_element = ElementOwned{ .argument = argument };
                        argument_element.deinit(allocator);
                    }

                    self.arguments.clearAndFree();
                }

                // Make sure the memory held by the properties list is freed no matter what
                defer {
                    var props_iter = self.properties.valueIterator();

                    while (props_iter.next()) |prop| {
                        var prop_element = ElementOwned{ .property = prop.* };
                        prop_element.deinit(allocator);
                    }

                    self.properties.clearAndFree();
                }

                for (self.arguments.items) |argument| {
                    try self.raw_printer.printElementOwned(ElementOwned{ .argument = argument });
                }

                // TODO Sort properties alphabetically

                var props_iter = self.properties.valueIterator();
                while (props_iter.next()) |prop| {
                    try self.raw_printer.printElementOwned(ElementOwned{ .property = prop.* });
                }
            }
        }

        pub fn printEndOfFile(self: *Self) !void {
            return self.raw_printer.printEndOfFile();
        }

        pub fn deinit(self: *Self) void {
            var allocator = self.raw_printer.allocator;

            for (self.arguments.items) |arg| arg.deinit(allocator);

            var iter = self.properties.valueIterator();
            while (iter.next()) |prop| prop.deinit(allocator);

            self.properties.deinit();
            self.arguments.deinit();
        }
    };
}

test "Single root node" {
    var allocator = std.testing.allocator;
    var buffer = std.ArrayList(u8).init(allocator);
    defer buffer.deinit();
    const BufferWriter = @TypeOf(buffer.writer());

    var printer = Printer(BufferWriter).init(allocator, buffer.writer());

    try printer.printNodeBegin("root", null);
    try printer.printProperty("prop", .{ .string = "test" }, null);
    try printer.printArgument(.{ .integer = 2 }, null);
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

    var printer = Printer(BufferWriter).init(allocator, buffer.writer());

    try printer.printNodeBegin("package", null);
    try printer.printProperty("prop", .{ .string = "test" }, null);
    try printer.printArgument(.{ .integer = 2 }, null);

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
        \\    childless
        \\    child {
        \\        childs-child
        \\    }
        \\    childless
        \\    child {
        \\        childs-child
        \\    }
        \\}
        \\
    , result);
}
