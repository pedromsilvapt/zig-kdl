const std = @import("std");
const assert = std.debug.assert;
const Allocator = std.mem.Allocator;
const Token = @import("./tokens.zig").Token;
const TokenKind = @import("./tokens.zig").TokenKind;
const Tokenizer = @import("./tokens.zig").Tokenizer;
const Location = @import("./tokens.zig").Location;

pub const Element = union(enum) {
    pub const NodeBegin = struct {
        name: Token,
        type_name: ?Token,
    };

    pub const Property = struct {
        name: Token,
        value: Value,
    };

    pub const Value = struct {
        type_name: ?Token,
        data: Token,
    };

    node_begin: NodeBegin,
    node_end: void,
    property: Property,
    argument: Value,
};

/// TODO Sync any changes made to this parser, to the FSM diagram stored in 
/// the file spec/parser.puml
pub const Parser = struct {
    pub const State = union(enum) {
        start: void,

        nodes: void,

        node_begin_type: void,
        node_begin_type_id: NodeType,
        node_begin_type_end: NodeType,
        node_begin_identifier: NodeBegin,
        node_begin_identifier_space: void,
        node_children: void,
        node_end: NodeEnd,

        property_or_argument: PropertyOrArgument,

        property: PropertyName,
        property_value: PropertyName,
        property_value_type: PropertyName,
        property_value_type_id: PropertyNameType,
        property_value_type_end: PropertyNameType,
        property_value_end: Property,

        argument: Argument,
        argument_type: void,
        argument_type_id: ArgumentType,
        argument_type_end: ArgumentType,

        end: void,

        pub const NodeType = struct {
            type_name: Token,
        };

        pub const NodeBegin = struct {
            name: Token,
            type_name: ?Token,
        };

        pub const NodeEnd = struct {
            braces: bool,
        };

        pub const PropertyOrArgument = struct {
            name: Token,
        };

        pub const PropertyName = struct {
            name: Token,
        };

        pub const PropertyNameType = struct {
            name: Token,
            type_name: Token,
        };

        pub const Property = struct {
            name: Token,
            type_name: ?Token,
            value_data: Token,
        };

        pub const Argument = struct {
            type_name: ?Token,
            value_data: Token,
        };

        pub const ArgumentType = struct {
            type_name: Token,
        };
    };

    pub const StateTag = std.meta.Tag(State);

    pub fn StatePayload(comptime tag: StateTag) type {
        return std.meta.TagPayload(State, tag);
    }

    tokenizer: Tokenizer,

    next_element: ?Element = null,

    state: State = .start,

    depth: usize = 0,

    double_end: bool = false,

    transitioned: bool = false,

    pub fn init(source: []const u8) !Parser {
        return Parser{
            .tokenizer = try Tokenizer.init(source),
        };
    }

    fn transition(self: *Parser, comptime state: StateTag, payload: StatePayload(state)) !void {
        var new_state = @unionInit(State, @tagName(state), payload);

        inline for (std.meta.fields(StateTag)) |field| {
            if (self.state == @field(StateTag, field.name)) {
                const leave_method_name = "leave_" ++ field.name;
                if (@hasDecl(Parser, leave_method_name)) {
                    try @call(.{}, @field(Parser, leave_method_name), .{ self, new_state });
                }
            }
        }

        const enter_method_name = "enter_" ++ @tagName(state);
        if (@hasDecl(Parser, enter_method_name)) {
            try @call(.{}, @field(Parser, enter_method_name), .{ self, payload });
        }

        self.transitioned = true;

        self.state = new_state;
    }

    pub fn enter_node_end(self: *Parser, new_state: StatePayload(.node_end)) !void {
        _ = new_state;

        assert(self.next_element == null);

        if (self.depth == 0) {
            return error.ParseError;
        }

        self.depth -= 1;

        self.next_element = Element{
            .node_end = {},
        };
    }

    pub fn enter_node_begin_identifier(self: *Parser, new_state: StatePayload(.node_begin_identifier)) !void {
        assert(self.next_element == null);

        self.double_end = true;

        self.depth += 1;

        self.next_element = Element{
            .node_begin = .{
                .name = new_state.name,
                .type_name = new_state.type_name,
            },
        };
    }

    pub fn enter_node_children(self: *Parser, new_state: StatePayload(.node_children)) !void {
        _ = new_state;

        self.double_end = false;
    }

    pub fn enter_property_value_end(self: *Parser, new_state: StatePayload(.property_value_end)) !void {
        assert(self.next_element == null);

        self.next_element = Element{
            .property = .{
                .name = new_state.name,
                .value = .{
                    .type_name = new_state.type_name,
                    .data = new_state.value_data,
                },
            },
        };
    }

    pub fn enter_argument(self: *Parser, new_state: StatePayload(.argument)) !void {
        assert(self.next_element == null);

        self.next_element = Element{
            .argument = .{
                .type_name = new_state.type_name,
                .data = new_state.value_data,
            },
        };
    }

    pub fn leave_property_or_argument(self: *Parser, new_state: State) !void {
        if (new_state == .node_end or
            new_state == .node_begin_identifier_space or
            new_state == .node_children)
        {
            assert(self.next_element == null);

            const argument_value = self.state.property_or_argument.name;

            self.next_element = Element{
                .argument = .{
                    .type_name = null,
                    .data = argument_value,
                },
            };
        }
    }

    pub fn next(self: *Parser) !?Element {
        @setEvalBranchQuota(10000);

        var element: ?Element = null;

        if (self.state == .node_end and
            self.double_end and
            self.state.node_end.braces and
            self.depth > 0)
        {
            self.double_end = false;

            self.depth -= 1;

            return Element{ .node_end = {} };
        }

        loop: while (self.state != .end) {
            self.transitioned = false;

            if (try self.tokenizer.next()) |token| {
                switch (self.state) {
                    .start, .nodes => {
                        // Ignore line spaces, keep the same state
                        if (token.kind == .newline or
                            token.kind == .ws or
                            token.kind == .single_line_comment)
                        {
                            try self.transition(.nodes, {});
                        }

                        if (token.kind == .curly_brace_close) {
                            try self.transition(.node_end, .{
                                .braces = true,
                            });
                        }

                        // TODO Handle slash-dash

                        if (token.kind == .brace_open) {
                            try self.transition(.node_begin_type, {});
                        }

                        if (token.kind == .bare_identifier or
                            token.kind == .raw_string or
                            token.kind == .escaped_string)
                        {
                            try self.transition(.node_begin_identifier, .{
                                .name = token,
                                .type_name = null,
                            });
                        }

                        if (token.kind == .eof) {
                            try self.transition(.end, {});
                        }
                    },
                    .node_begin_type => {
                        if (token.kind == .bare_identifier or
                            token.kind == .raw_string or
                            token.kind == .escaped_string)
                        {
                            try self.transition(.node_begin_type_id, .{
                                .type_name = token,
                            });
                        }
                    },
                    .node_begin_type_end => |state| {
                        if (token.kind == .brace_close) {
                            try self.transition(.node_begin_type_end, .{
                                .type_name = state.type_name,
                            });
                        }
                    },
                    .node_begin_type_id => |state| {
                        if (token.kind == .bare_identifier or
                            token.kind == .raw_string or
                            token.kind == .escaped_string)
                        {
                            try self.transition(.node_begin_identifier, .{
                                .name = token,
                                .type_name = state.type_name,
                            });
                        }
                    },
                    .node_begin_identifier => {
                        // Node terminator
                        if (token.kind == .single_line_comment or
                            token.kind == .newline or
                            token.kind == .semicolon or
                            token.kind == .curly_brace_close)
                        {
                            try self.transition(.node_end, .{
                                .braces = token.kind == .curly_brace_close,
                            });
                        }

                        // End of file should go to the .end state always
                        if (token.kind == .eof) {
                            try self.transition(.end, {});
                        }

                        if (token.kind == .ws or
                            token.kind == .escline)
                        {
                            try self.transition(.node_begin_identifier_space, {});
                        }

                        if (token.kind == .curly_brace_open) {
                            try self.transition(.node_children, {});
                        }
                    },
                    .node_begin_identifier_space => {
                        // Node terminator
                        if (token.kind == .single_line_comment or
                            token.kind == .newline or
                            token.kind == .semicolon or
                            token.kind == .curly_brace_close)
                        {
                            try self.transition(.node_end, .{
                                .braces = token.kind == .curly_brace_close,
                            });
                        }

                        if (token.kind == .eof) {
                            try self.transition(.end, {});
                        }

                        if (token.kind == .ws or
                            token.kind == .escline)
                        {
                            try self.transition(.node_begin_identifier_space, {});
                        }

                        if (token.kind == .curly_brace_open) {
                            try self.transition(.node_children, {});
                        }

                        if (token.kind == .escaped_string or
                            token.kind == .raw_string)
                        {
                            try self.transition(.property_or_argument, .{
                                .name = token,
                            });
                        }

                        if (token.kind == .bare_identifier) {
                            try self.transition(.property, .{
                                .name = token,
                            });
                        }

                        if (token.kind == .decimal or
                            token.kind == .signed_integer or
                            token.kind == .hex or
                            token.kind == .octal or
                            token.kind == .binary or
                            token.kind == .keyword)
                        {
                            try self.transition(.argument, .{
                                .type_name = null,
                                .value_data = token,
                            });
                        }

                        if (token.kind == .brace_open) {
                            try self.transition(.argument_type, {});
                        }
                    },
                    .node_children => {
                        if (token.kind == .newline or
                            token.kind == .ws or
                            token.kind == .single_line_comment)
                        {
                            try self.transition(.node_children, {});
                        }

                        if (token.kind == .brace_open) {
                            try self.transition(.node_begin_type, {});
                        }

                        if (token.kind == .bare_identifier or
                            token.kind == .escaped_string or
                            token.kind == .raw_string)
                        {
                            try self.transition(.node_begin_identifier, .{
                                .name = token,
                                .type_name = null,
                            });
                        }
                    },
                    .node_end => {
                        if (token.kind == .newline or
                            token.kind == .ws or
                            token.kind == .single_line_comment)
                        {
                            try self.transition(.nodes, {});
                        }

                        if (token.kind == .eof) {
                            try self.transition(.end, {});
                        }

                        if (token.kind == .curly_brace_close) {
                            try self.transition(.node_end, .{
                                .braces = true,
                            });
                        }

                        if (token.kind == .brace_open) {
                            try self.transition(.node_begin_type, {});
                        }

                        if (token.kind == .bare_identifier or
                            token.kind == .escaped_string or
                            token.kind == .raw_string)
                        {
                            try self.transition(.node_begin_identifier, .{
                                .name = token,
                                .type_name = null,
                            });
                        }
                    },
                    .property_or_argument => |state| {
                        if (token.kind == .single_line_comment or
                            token.kind == .newline or
                            token.kind == .semicolon or
                            token.kind == .curly_brace_close)
                        {
                            try self.transition(.node_end, .{
                                .braces = token.kind == .curly_brace_close,
                            });
                        }

                        if (token.kind == .eof) {
                            try self.transition(.end, {});
                        }

                        if (token.kind == .ws or
                            token.kind == .escline)
                        {
                            try self.transition(.node_begin_identifier_space, {});
                        }

                        if (token.kind == .curly_brace_open) {
                            try self.transition(.node_children, {});
                        }

                        if (token.kind == .equals) {
                            try self.transition(.property_value, .{
                                .name = state.name,
                            });
                        }
                    },
                    .property => |state| {
                        if (token.kind == .equals) {
                            try self.transition(.property_value, .{
                                .name = state.name,
                            });
                        }
                    },
                    .property_value => |state| {
                        if (token.kind == .brace_open) {
                            try self.transition(.property_value_type, .{
                                .name = state.name,
                            });
                        }

                        if (token.kind == .raw_string or
                            token.kind == .escaped_string or
                            token.kind == .decimal or
                            token.kind == .signed_integer or
                            token.kind == .hex or
                            token.kind == .octal or
                            token.kind == .binary or
                            token.kind == .keyword)
                        {
                            try self.transition(.property_value_end, .{
                                .name = state.name,
                                .type_name = null,
                                .value_data = token,
                            });
                        }
                    },
                    .property_value_type => |state| {
                        if (token.kind == .bare_identifier or
                            token.kind == .raw_string or
                            token.kind == .escaped_string)
                        {
                            try self.transition(.property_value_type_id, .{
                                .name = state.name,
                                .type_name = token,
                            });
                        }
                    },
                    .property_value_type_id => |state| {
                        if (token.kind == .brace_close) {
                            try self.transition(.property_value_type_end, .{
                                .name = state.name,
                                .type_name = state.type_name,
                            });
                        }
                    },
                    .property_value_type_end => |state| {
                        if (token.kind == .raw_string or
                            token.kind == .escaped_string or
                            token.kind == .decimal or
                            token.kind == .signed_integer or
                            token.kind == .hex or
                            token.kind == .octal or
                            token.kind == .binary or
                            token.kind == .keyword)
                        {
                            try self.transition(.property_value_end, .{
                                .name = state.name,
                                .type_name = state.type_name,
                                .value_data = token,
                            });
                        }
                    },
                    .property_value_end => {
                        if (token.kind == .single_line_comment or
                            token.kind == .newline or
                            token.kind == .semicolon or
                            token.kind == .curly_brace_close)
                        {
                            try self.transition(.node_end, .{
                                .braces = token.kind == .curly_brace_close,
                            });
                        }

                        if (token.kind == .eof) {
                            try self.transition(.end, {});
                        }

                        if (token.kind == .ws or
                            token.kind == .escline)
                        {
                            try self.transition(.node_begin_identifier_space, {});
                        }

                        if (token.kind == .curly_brace_open) {
                            try self.transition(.node_children, {});
                        }
                    },
                    .argument => {
                        if (token.kind == .single_line_comment or
                            token.kind == .newline or
                            token.kind == .semicolon or
                            token.kind == .curly_brace_close)
                        {
                            try self.transition(.node_end, .{
                                .braces = token.kind == .curly_brace_close,
                            });
                        }

                        if (token.kind == .eof) {
                            try self.transition(.end, {});
                        }

                        if (token.kind == .ws or
                            token.kind == .escline)
                        {
                            try self.transition(.node_begin_identifier_space, {});
                        }

                        if (token.kind == .curly_brace_open) {
                            try self.transition(.node_children, {});
                        }
                    },
                    .argument_type => {
                        if (token.kind == .bare_identifier or
                            token.kind == .raw_string or
                            token.kind == .escaped_string)
                        {
                            try self.transition(.argument_type_id, .{
                                .type_name = token,
                            });
                        }
                    },
                    .argument_type_id => |state| {
                        if (token.kind == .brace_close) {
                            try self.transition(.argument_type_end, .{
                                .type_name = state.type_name,
                            });
                        }
                    },
                    .argument_type_end => |state| {
                        if (token.kind == .raw_string or
                            token.kind == .escaped_string or
                            token.kind == .decimal or
                            token.kind == .signed_integer or
                            token.kind == .hex or
                            token.kind == .octal or
                            token.kind == .binary or
                            token.kind == .keyword)
                        {
                            try self.transition(.argument, .{
                                .type_name = state.type_name,
                                .value_data = token,
                            });
                        }
                    },
                    .end => {
                        break :loop;
                    },
                }
            }

            if (self.transitioned) {
                if (self.next_element) |elem| {
                    element = elem;

                    self.next_element = null;

                    break :loop;
                }
            } else if (self.state != .end) {
                return error.ParseError;
            }
        }

        if (self.state == .end and element == null and self.depth > 0) {
            self.depth -= 1;

            element = Element{ .node_end = {} };
        }

        return element;
    }

    // pub fn freeElement(self: *const Parser, scalar: Element) void {
    //     switch (element) {
    //         .node_begin => |payload| {
    //             self.allocator.free(payload.name);

    //             if (payload.type_name) |type_name| {
    //                 self.allocator.free(type_name);
    //             }
    //         },
    //         .property => |payload| {
    //             self.allocator.free(payload.name);

    //             self.freeValue(payload.value);
    //         },
    //         .argument => |payload| {
    //             self.freeValue(payload);
    //         },
    //         else => {},
    //     }
    // }

    // pub fn freeValue(self: *const Parser, value: Element.Value) void {
    //     if (value.type_name) |type_name| {
    //         self.allocator.free(type_name);
    //     }

    //     if (value.data == .string) {
    //         self.allocator.free(value.data.string);
    //     }
    // }
};

fn expectNodeBegin(parser: *Parser, allocator: Allocator, name: []const u8, type_name: ?[]const u8) !void {
    var element = try parser.next();

    // Make sure the element is not null
    try std.testing.expect(element != null);

    try std.testing.expect(element.? == .node_begin);

    // Get the name string
    const actual_name = try element.?.node_begin.name.toString(allocator);
    defer allocator.free(actual_name);

    try std.testing.expectEqualStrings(name, actual_name);

    if (type_name == null) {
        try std.testing.expect(element.?.node_begin.type_name == null);
    } else {
        try std.testing.expect(element.?.node_begin.type_name != null);

        const actual_type_name = try element.?.node_begin.type_name.?.toString(allocator);
        defer allocator.free(actual_type_name);

        try std.testing.expectEqualStrings(type_name.?, actual_type_name);
    }
}

fn expectNodeEnd(parser: *Parser) !void {
    var element = try parser.next();

    // Make sure the element is not null
    try std.testing.expect(element != null);

    try std.testing.expect(element.? == .node_end);
}

fn expectProperty(parser: *Parser, allocator: Allocator, name: []const u8, value: anytype, type_name: ?[]const u8) !void {
    var element = try parser.next();

    // Make sure the element is not null
    try std.testing.expect(element != null);

    try std.testing.expect(element.? == .property);

    // Get the name string
    const actual_name = try element.?.property.name.toString(allocator);
    defer allocator.free(actual_name);

    try std.testing.expectEqualStrings(name, actual_name);

    try expectValueData(allocator, element.?.property.value.data, value);

    if (type_name == null) {
        try std.testing.expect(element.?.property.value.type_name == null);
    } else {
        try std.testing.expect(element.?.property.value.type_name != null);

        const actual_type_name = try element.?.property.value.type_name.?.toString(allocator);
        defer allocator.free(actual_type_name);

        try std.testing.expectEqualStrings(type_name.?, actual_type_name);
    }
}

fn expectArgument(parser: *Parser, allocator: Allocator, value: anytype, type_name: ?[]const u8) !void {
    var element = try parser.next();

    // Make sure the element is not null
    try std.testing.expect(element != null);

    try std.testing.expect(element.? == .argument);

    try expectValueData(allocator, element.?.argument.data, value);

    if (type_name == null) {
        try std.testing.expect(element.?.argument.type_name == null);
    } else {
        try std.testing.expect(element.?.argument.type_name != null);

        const actual_type_name = try element.?.argument.type_name.?.toString(allocator);
        defer allocator.free(actual_type_name);

        try std.testing.expectEqualStrings(type_name.?, actual_type_name);
    }
}

fn expectNull(parser: *Parser) !void {
    var element = try parser.next();

    // Make sure the element is null
    try std.testing.expect(element == null);
}

fn expectValueData(allocator: Allocator, value_token: Token, expected: anytype) !void {
    const type_info = @typeInfo(@TypeOf(expected));

    var value = try value_token.toScalar(allocator);
    defer value.deinit(allocator);

    if (type_info == .Int or type_info == .ComptimeInt) {
        try std.testing.expect(value == .integer);
        try std.testing.expectEqual(@intCast(i64, expected), value.integer);
    } else if (type_info == .Float or type_info == .ComptimeFloat) {
        try std.testing.expect(value == .decimal);
        try std.testing.expectEqual(@floatCast(f64, expected), value.decimal);
    } else if (type_info == .Bool) {
        try std.testing.expect(value == .boolean);
        try std.testing.expectEqual(expected, value.boolean);
    } else if (type_info == .Void) {
        try std.testing.expect(value == .none);
    } else if (type_info == .Pointer) {
        try std.testing.expect(value == .string);
        try std.testing.expectEqualStrings(expected, value.string);
    } else {
        // Unsupported type
        try std.testing.expect(false);
    }
}

test "Basic node_begin/node_end parser test" {
    var allocator = std.testing.allocator;

    var parser = try Parser.init("");
    try std.testing.expect((try parser.next()) == null);

    parser = try Parser.init("node { node1; node2 }");
    try expectNodeBegin(&parser, allocator, "node", null);
    try expectNodeBegin(&parser, allocator, "node1", null);
    try expectNodeEnd(&parser);
    try expectNodeBegin(&parser, allocator, "node2", null);
    try expectNodeEnd(&parser);
    try expectNodeEnd(&parser);
    try expectNull(&parser);
}

test "Basic arguments/properties parser test" {
    var allocator = std.testing.allocator;

    var parser = try Parser.init("");
    try std.testing.expect((try parser.next()) == null);

    parser = try Parser.init(
        \\ node "foo" { 
        \\      node1 prop=1 prop=2.1; node2 true null
        \\ }
    );
    try expectNodeBegin(&parser, allocator, "node", null);
    try expectArgument(&parser, allocator, "foo", null);
    try expectNodeBegin(&parser, allocator, "node1", null);
    try expectProperty(&parser, allocator, "prop", 1, null);
    try expectProperty(&parser, allocator, "prop", 2.1, null);
    try expectNodeEnd(&parser);
    try expectNodeBegin(&parser, allocator, "node2", null);
    try expectArgument(&parser, allocator, true, null);
    try expectArgument(&parser, allocator, {}, null);
    try expectNodeEnd(&parser);
    try expectNodeEnd(&parser);
    try expectNull(&parser);
}

test "Terminate curly braces same line" {
    var allocator = std.testing.allocator;

    var parser = try Parser.init("");
    try std.testing.expect((try parser.next()) == null);

    parser = try Parser.init(
        \\ node "foo" { node1 prop=1 prop=2.1; node2 true null }
        \\ node "foo" { node1 prop=1 prop=2.1; node2 true null }
    );
    try expectNodeBegin(&parser, allocator, "node", null);
    try expectArgument(&parser, allocator, "foo", null);
    try expectNodeBegin(&parser, allocator, "node1", null);
    try expectProperty(&parser, allocator, "prop", 1, null);
    try expectProperty(&parser, allocator, "prop", 2.1, null);
    try expectNodeEnd(&parser);
    try expectNodeBegin(&parser, allocator, "node2", null);
    try expectArgument(&parser, allocator, true, null);
    try expectArgument(&parser, allocator, {}, null);
    try expectNodeEnd(&parser);
    try expectNodeEnd(&parser);
    try expectNodeBegin(&parser, allocator, "node", null);
    try expectArgument(&parser, allocator, "foo", null);
    try expectNodeBegin(&parser, allocator, "node1", null);
    try expectProperty(&parser, allocator, "prop", 1, null);
    try expectProperty(&parser, allocator, "prop", 2.1, null);
    try expectNodeEnd(&parser);
    try expectNodeBegin(&parser, allocator, "node2", null);
    try expectArgument(&parser, allocator, true, null);
    try expectArgument(&parser, allocator, {}, null);
    try expectNodeEnd(&parser);
    try expectNodeEnd(&parser);
    try expectNull(&parser);
}
