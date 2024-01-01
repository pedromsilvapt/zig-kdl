const std = @import("std");
const builtin = @import("builtin");
const assert = std.debug.assert;
const Allocator = std.mem.Allocator;
const Token = @import("./tokens.zig").Token;
const TokenKind = @import("./tokens.zig").TokenKind;
const Tokenizer = @import("./tokens.zig").Tokenizer;

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

    pub const Slashdash = struct {
        scope: SlashdashScope,
    };

    pub const SlashdashScope = enum { node, node_children, property_or_argument };

    node_begin: NodeBegin,
    node_end: void,
    property: Property,
    argument: Value,
    slashdash: Slashdash,

    pub fn toOwned(self: *const Element, allocator: Allocator) !ElementOwned {
        switch (self.*) {
            .node_begin => |node| {
                var name = try node.name.toString(allocator);
                errdefer allocator.free(name);

                var type_name = if (node.type_name) |type_name_token|
                    try type_name_token.toString(allocator)
                else
                    null;
                errdefer if (type_name) |type_name_str| allocator.free(type_name_str);

                return ElementOwned{
                    .node_begin = .{
                        .name = name,
                        .type_name = type_name,
                    },
                };
            },
            .node_end => {
                return ElementOwned{ .node_end = {} };
            },
            .property => |prop| {
                var name = try prop.name.toString(allocator);
                errdefer allocator.free(name);

                var type_name = if (prop.value.type_name) |type_name_token|
                    try type_name_token.toString(allocator)
                else
                    null;
                errdefer if (type_name) |type_name_str| allocator.free(type_name_str);

                var data = try prop.value.data.toScalar(allocator);
                errdefer data.deinit(allocator);

                return ElementOwned{
                    .property = .{
                        .name = name,
                        .value = .{ .data = data, .type_name = type_name },
                    },
                };
            },
            .argument => |value| {
                var data = try value.data.toScalar(allocator);
                errdefer data.deinit(allocator);

                var type_name = if (value.type_name) |type_name_token|
                    try type_name_token.toString(allocator)
                else
                    null;
                errdefer if (type_name) |type_name_str| allocator.free(type_name_str);

                return ElementOwned{ .argument = .{
                    .data = data,
                    .type_name = type_name,
                } };
            },
            .slashdash => |slashdash| {
                return ElementOwned{ .slashdash = slashdash };
            },
        }
    }
};

pub const ElementOwned = union(enum) {
    pub const NodeBegin = struct {
        name: []const u8,
        type_name: ?[]const u8,

        pub fn deinit(self: *const NodeBegin, allocator: Allocator) void {
            allocator.free(self.name);

            if (self.type_name) |type_name| {
                allocator.free(type_name);
            }
        }
    };

    pub const Property = struct {
        name: []const u8,
        value: Value,

        pub fn deinit(self: *const Property, allocator: Allocator) void {
            allocator.free(self.name);

            self.value.deinit(allocator);
        }
    };

    pub const Value = struct {
        type_name: ?[]const u8,
        data: Token.Scalar,

        pub fn deinit(self: *const Value, allocator: Allocator) void {
            self.data.deinit(allocator);

            if (self.type_name) |type_name| {
                allocator.free(type_name);
            }
        }
    };

    pub const Slashdash = Element.Slashdash;

    pub const SlashdashScope = Element.SlashdashScope;

    node_begin: NodeBegin,
    node_end: void,
    property: Property,
    argument: Value,
    slashdash: Slashdash,

    pub fn initNodeBegin(name: []const u8, type_name: ?[]const u8) ElementOwned {
        return .{
            .node_begin = .{
                .name = name,
                .type_name = type_name,
            },
        };
    }

    pub fn initNodeEnd() Element {
        return .{ .node_end = {} };
    }

    pub fn initProperty(name: []const u8, data: Token.Scalar, type_name: ?[]const u8) !ElementOwned {
        return .{
            .property = .{
                .name = name,
                .value = .{
                    .type_name = type_name,
                    .data = data,
                },
            },
        };
    }

    pub fn initArgument(data: Token.Scalar, type_name: ?[]const u8) !ElementOwned {
        return .{
            .argument = .{
                .type_name = type_name,
                .data = data,
            },
        };
    }

    pub fn initSlashdash(scope: SlashdashScope) ElementOwned {
        return .{
            .slashdash = .{
                .scope = scope,
            },
        };
    }

    pub fn deinit(self: *const ElementOwned, allocator: Allocator) void {
        switch (self.*) {
            .node_begin => |node| node.deinit(allocator),
            .property => |prop| prop.deinit(allocator),
            .argument => |value| value.deinit(allocator),
            .slashdash, .node_end => {},
        }
    }
};

/// TODO Sync any changes made to this parser, to the FSM diagram stored in
/// the file spec/parser.puml
pub const Parser = struct {
    pub const State = union(enum) {
        start: void,

        nodes: void,

        node_begin_slashdash: void,
        node_begin_type: void,
        node_begin_type_id: NodeType,
        node_begin_type_end: NodeType,
        node_begin_identifier: NodeBegin,
        node_begin_identifier_space: void,
        node_inner_slashdash: void,
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

        escline: Escline,
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

        pub const Escline = union(enum) {
            node_begin_slashdash: void,
            node_inner_slashdash: void,
            node_begin_identifier_space: void,
        };
    };

    pub const StateTag = std.meta.Tag(State);

    pub fn StatePayload(comptime tag: StateTag) type {
        return std.meta.TagPayload(State, tag);
    }

    tokenizer: Tokenizer,

    next_elements: CircularBuffer(Element, 3) = .{},

    slashdash_filter: SlashdashElementsFilter = .{},

    state: State = .start,

    depth: usize = 0,

    has_children: bool = true,

    transitioned: bool = false,

    /// Field which controls if this parser should print debugging messages
    /// Is only available when building in debug mode, for performance reasons
    debug: bool = false,

    pub fn init(source: []const u8) !Parser {
        return Parser{
            .tokenizer = try Tokenizer.init(source),
        };
    }

    fn log(self: *Parser, comptime format: []const u8, args: anytype) void {
        // Comptime check to improve performance on non-debug builds
        if (builtin.mode == .Debug) {
            if (self.debug) {
                std.log.warn(format, args);
            }
        }
    }

    fn transition(self: *Parser, comptime state: StateTag, payload: StatePayload(state)) !void {
        std.debug.assert(self.transitioned == false);

        // Debug helper
        const cursor = self.tokenizer.reader.location;
        self.log("New state: " ++ @tagName(state) ++ " at cursor pos Line {d} Col {d}.", .{ cursor.line, cursor.column });

        var new_state = @unionInit(State, @tagName(state), payload);

        inline for (std.meta.fields(StateTag)) |field| {
            if (self.state == @field(StateTag, field.name)) {
                const leave_method_name = "leave_" ++ field.name;
                if (@hasDecl(Parser, leave_method_name)) {
                    self.log("  Calling " ++ leave_method_name ++ "...", .{});
                    try @call(.auto, @field(Parser, leave_method_name), .{ self, new_state });
                }
            }
        }

        const enter_method_name = "enter_" ++ @tagName(state);
        if (@hasDecl(Parser, enter_method_name)) {
            self.log("  Calling " ++ enter_method_name ++ "...", .{});
            try @call(.auto, @field(Parser, enter_method_name), .{ self, payload });
        }

        self.transitioned = true;

        self.state = new_state;
    }

    pub fn enter_node_end(self: *Parser, new_state: StatePayload(.node_end)) !void {
        if (self.depth == 0) {
            return error.ParseError;
        }

        self.log(">> Node end, depth {d}", .{self.depth});

        self.depth -= 1;

        self.enqueue(Element{
            .node_end = {},
        });

        // If we are closig a node with braces, and it has no children, we need to emit two
        // consecutive .node_end elements
        // For example, when we have the following scenario: node1 { node2 }
        if (!self.has_children and new_state.braces) {
            if (self.depth == 0) {
                return error.ParseError;
            }

            self.depth -= 1;

            self.enqueue(Element{
                .node_end = {},
            });
        }

        // If we just closed a node, that means we are now one level up
        // And the node on that level (the parent node) for sure has children
        // At least, it must always have the node we just closed as a child!
        self.has_children = true;
    }

    pub fn enter_node_begin_slashdash(self: *Parser, new_state: StatePayload(.node_begin_slashdash)) !void {
        _ = new_state;

        self.enqueue(Element{ .slashdash = .{ .scope = .node } });
    }

    pub fn enter_node_begin_identifier(self: *Parser, new_state: StatePayload(.node_begin_identifier)) !void {
        self.has_children = false;

        self.depth += 1;

        self.enqueue(Element{
            .node_begin = .{
                .name = new_state.name,
                .type_name = new_state.type_name,
            },
        });
    }

    pub fn leave_node_inner_slashdash(self: *Parser, new_state: State) !void {
        // If we just found a whitespace or something similar, do nothing
        // Similarly,since we know that when we go to .escline, we will have to go back again,
        // we do nothing for now and wait for when we really exit the state
        if (new_state == .node_inner_slashdash or new_state == .escline) {
            return;
        }

        if (new_state == .node_children) {
            self.enqueue(Element{
                .slashdash = .{
                    .scope = .node_children,
                },
            });
        } else {
            self.enqueue(Element{
                .slashdash = .{
                    .scope = .property_or_argument,
                },
            });
        }
    }

    pub fn enter_node_children(self: *Parser, new_state: StatePayload(.node_children)) !void {
        _ = new_state;

        self.has_children = true;
    }

    pub fn enter_property_value_end(self: *Parser, new_state: StatePayload(.property_value_end)) !void {
        self.enqueue(Element{
            .property = .{
                .name = new_state.name,
                .value = .{
                    .type_name = new_state.type_name,
                    .data = new_state.value_data,
                },
            },
        });
    }

    pub fn enter_argument(self: *Parser, new_state: StatePayload(.argument)) !void {
        self.enqueue(Element{
            .argument = .{
                .type_name = new_state.type_name,
                .data = new_state.value_data,
            },
        });
    }

    pub fn leave_property_or_argument(self: *Parser, new_state: State) !void {
        if (new_state == .node_end or
            new_state == .node_begin_identifier_space or
            new_state == .node_children or
            new_state == .end)
        {
            const argument_value = self.state.property_or_argument.name;

            self.enqueue(Element{
                .argument = .{
                    .type_name = null,
                    .data = argument_value,
                },
            });
        }
    }

    fn enqueue(self: *Parser, element: Element) void {
        if (!self.slashdash_filter.check(element)) {
            self.log(" ! Emitting node {?}", .{element});

            self.next_elements.enqueueAssumeCapacity(element);
        } else {
            self.log(" ! Skipping node {?}", .{element});
        }
    }

    pub fn next(self: *Parser) !?Element {
        @setEvalBranchQuota(10000);

        return loop: while (true) {
            self.transitioned = false;

            // If there are no more elements queued, but our depth is still to big, we
            // need to emit as many .node_end elements as possible to get the depth to zero
            if (self.state == .end and self.next_elements.len == 0 and self.depth > 0) {
                self.depth -= 1;

                self.enqueue(Element{ .node_end = {} });
            }

            var element = self.next_elements.tryDequeue();

            if (element != null or self.state == .end) {
                break :loop element;
            }

            if (try self.tokenizer.next()) |token| {
                self.log("Read token {any}: <<{s}>>", .{ token.kind, token.text });

                switch (self.state) {
                    .start, .nodes => {
                        // Ignore line spaces, keep the same state
                        if (token.kind == .ws or
                            // token.kind == .escline or
                            token.kind == .newline or
                            token.kind == .single_line_comment)
                        {
                            try self.transition(.nodes, {});
                        }

                        if (token.kind == .curly_brace_close) {
                            try self.transition(.node_end, .{
                                .braces = true,
                            });
                        }

                        if (token.kind == .slashdash) {
                            try self.transition(.node_begin_slashdash, {});
                        }

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
                    .node_begin_slashdash => {
                        if (token.kind == .escline) {
                            try self.transition(.escline, .{
                                .node_inner_slashdash = {},
                            });
                        }

                        // Ignore line spaces, keep the same state
                        if (token.kind == .ws) {
                            try self.transition(.node_begin_slashdash, {});
                        }

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
                    },
                    .node_begin_type => {
                        if (token.kind == .bare_identifier or
                            token.kind == .raw_string or
                            token.kind == .escaped_string)
                        {
                            try self.transition(.node_begin_type_end, .{
                                .type_name = token,
                            });
                        }
                    },
                    .node_begin_type_end => |state| {
                        if (token.kind == .brace_close) {
                            try self.transition(.node_begin_type_id, .{
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
                        if (token.kind == .escline) {
                            try self.transition(.escline, .{
                                .node_begin_identifier_space = {},
                            });
                        }

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

                        if (token.kind == .ws) {
                            try self.transition(.node_begin_identifier_space, {});
                        }

                        // There is no direct transition to .node_children when curly braces are found,
                        // because at least one space should always be present between the node identifier and the curly braces
                    },
                    .node_begin_identifier_space => {
                        if (token.kind == .escline) {
                            try self.transition(.escline, .{
                                .node_begin_identifier_space = {},
                            });
                        }

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

                        if (token.kind == .ws) {
                            try self.transition(.node_begin_identifier_space, {});
                        }

                        if (token.kind == .slashdash) {
                            try self.transition(.node_inner_slashdash, {});
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
                    .node_inner_slashdash => {
                        if (token.kind == .escline) {
                            try self.transition(.escline, .{
                                .node_inner_slashdash = {},
                            });
                        }

                        if (token.kind == .ws) // TODO escline vs single line comment (other states as well)
                        {
                            try self.transition(.node_inner_slashdash, {});
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

                        if (token.kind == .slashdash) {
                            try self.transition(.node_begin_slashdash, {});
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

                        if (token.kind == .curly_brace_close) {
                            try self.transition(.node_end, .{
                                .braces = true,
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

                        if (token.kind == .slashdash) {
                            try self.transition(.node_begin_slashdash, {});
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
                        if (token.kind == .escline) {
                            try self.transition(.escline, .{
                                .node_begin_identifier_space = {},
                            });
                        }

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

                        if (token.kind == .ws) {
                            try self.transition(.node_begin_identifier_space, {});
                        }

                        if (token.kind == .slashdash) {
                            try self.transition(.node_inner_slashdash, {});
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
                        if (token.kind == .escline) {
                            try self.transition(.escline, .{
                                .node_begin_identifier_space = {},
                            });
                        }

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

                        if (token.kind == .ws) {
                            try self.transition(.node_begin_identifier_space, {});
                        }

                        if (token.kind == .slashdash) {
                            try self.transition(.node_inner_slashdash, {});
                        }

                        if (token.kind == .curly_brace_open) {
                            try self.transition(.node_children, {});
                        }
                    },
                    .argument => {
                        if (token.kind == .escline) {
                            try self.transition(.escline, .{
                                .node_begin_identifier_space = {},
                            });
                        }

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

                        if (token.kind == .ws) {
                            try self.transition(.node_begin_identifier_space, {});
                        }

                        if (token.kind == .slashdash) {
                            try self.transition(.node_inner_slashdash, {});
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
                    .escline => |state| {
                        // Ignore line spaces, keep the same state
                        if (token.kind == .ws) {
                            try self.transition(.escline, state);
                        }

                        if (token.kind == .newline or
                            token.kind == .single_line_comment)
                        {
                            switch (state) {
                                .node_begin_slashdash => |prev_state| try self.transition(.node_begin_slashdash, prev_state),
                                .node_inner_slashdash => |prev_state| try self.transition(.node_inner_slashdash, prev_state),
                                .node_begin_identifier_space => |prev_state| try self.transition(.node_begin_identifier_space, prev_state),
                            }
                        }
                    },
                    .end => {},
                }
            } else {
                self.log("No token emitted.", .{});
            }

            if (!self.transitioned and self.state != .end) {
                return error.ParseError;
            }
        };
    }
};

// Receives all elements emitted by the parser, and provides an easy way to know
// if the element in question is part of a slashdash comment or not.
pub const SlashdashElementsFilter = struct {
    /// When this flag is false, the `test` method will return false for elements
    /// outside slashdash comments and true for elements inside.
    /// When it is true, it will reverse those values
    invert: bool = false,
    _slashdash_scope: ?Element.SlashdashScope = null,
    _slashdash_depth: i32 = 0,

    pub fn check(self: *SlashdashElementsFilter, element: Element) bool {
        var is_inside_slashdash = false;

        switch (element) {
            .slashdash => |slashdash| {
                // If we are inside a slashdash, no matter what type, and we find
                // another slashdash comment, nothing really changes. Only the first
                // slashdash we find counts, everything else inside of
                // it can be assumed to be inside a slashdash comment
                is_inside_slashdash = true;
                if (self._slashdash_scope == null) {
                    self._slashdash_scope = slashdash.scope;

                    // When the scope is .node, we will receive a .node_begin (which will
                    // increase the depth by 1) , and so it's matching node_end will
                    // be received when the depth == 1, and will close the slashdash there.
                    // But for scope == .node_children, the .node_begin will already have
                    // been emitted before the slashdash, which means the next .node_begin
                    // will be for one of the children. And we don't want to close the slashdash
                    // comment right after the node_end of the first child node, we want only after
                    // the node_end of the parent node (one level up)
                    // That's why we make the depth start in 1 instead of 0, we it takes one
                    // extra .node_end to close the slashdash comment
                    if (slashdash.scope == .node_children) {
                        self._slashdash_depth = 1;
                    }
                }
            },
            .node_begin => {
                if (self._slashdash_scope != null) {
                    self._slashdash_depth += 1;
                    is_inside_slashdash = true;
                }
            },
            .node_end => {
                if (self._slashdash_scope != null) {
                    std.debug.assert(self._slashdash_depth > 0);

                    self._slashdash_depth -= 1;

                    is_inside_slashdash = self._slashdash_depth > 0 or self._slashdash_scope.? == .node;

                    if (self._slashdash_depth == 0) {
                        self._slashdash_scope = null;
                    }
                }
            },
            .argument, .property => {
                if (self._slashdash_scope) |scope| {
                    is_inside_slashdash = true;

                    if (scope == .property_or_argument) {
                        self._slashdash_scope = null;
                    }
                }
            },
        }

        if (self.invert) {
            return !is_inside_slashdash;
        } else {
            return is_inside_slashdash;
        }
    }
};

fn CircularBuffer(comptime T: type, comptime N: comptime_int) type {
    return struct {
        const Self = @This();

        data: [N]T = undefined,
        len: usize = 0,
        capacity: usize = N,
        _cursor: usize = N,

        pub fn get(self: *const Self, index: usize) T {
            std.debug.assert(index >= 0);
            std.debug.assert(index < self.len);

            const real_index = (N + self._cursor - self.len + index) % N;

            return self.data[real_index];
        }

        pub fn enqueue(self: *Self, value: T) !void {
            if (self.len >= N) return error.NoCapacity;

            self.data[self._cursor % N] = value;

            self._cursor = (self._cursor + 1) % N;
            self.len += 1;
        }

        pub fn enqueueAssumeCapacity(self: *Self, value: T) void {
            self.enqueue(value) catch unreachable;
        }

        pub fn dequeue(self: *Self) !T {
            if (self.len <= 0) return error.EmptyBuffer;

            var value = self.get(0);

            self.len -= 1;

            return value;
        }

        pub fn tryDequeue(self: *Self) ?T {
            return if (self.len > 0)
                self.dequeue() catch unreachable
            else
                null;
        }
    };
}

test "CircularBuffer" {
    var buffer = CircularBuffer(i32, 3){};

    try std.testing.expectEqual(@as(usize, 0), buffer.len);
    try std.testing.expectEqual(@as(usize, 3), buffer.capacity);

    try buffer.enqueue(1);
    try buffer.enqueue(2);
    try buffer.enqueue(3);

    try std.testing.expectEqual(@as(usize, 3), buffer.len);
    try std.testing.expectEqual(@as(i32, 1), buffer.get(0));
    try std.testing.expectEqual(@as(i32, 2), buffer.get(1));
    try std.testing.expectEqual(@as(i32, 3), buffer.get(2));

    try std.testing.expectEqual(@as(i32, 1), try buffer.dequeue());
    try buffer.enqueue(4);
    try std.testing.expectEqual(@as(i32, 2), try buffer.dequeue());
    try std.testing.expectEqual(@as(i32, 3), try buffer.dequeue());
    try buffer.enqueue(5);
    try std.testing.expectEqual(@as(i32, 4), try buffer.dequeue());
    try std.testing.expectEqual(@as(i32, 5), try buffer.dequeue());

    try std.testing.expectEqual(@as(usize, 0), buffer.len);
}

fn expectNodeBegin(parser: *Parser, allocator: Allocator, name: []const u8, type_name: ?[]const u8) !void {
    var element = try parser.next();

    // Make sure the element is not null
    try std.testing.expect(element != null);

    try std.testing.expectEqualStrings("node_begin", @tagName(element.?));

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

    try std.testing.expectEqualStrings("node_end", @tagName(element.?));
}

fn expectProperty(parser: *Parser, allocator: Allocator, name: []const u8, value: anytype, type_name: ?[]const u8) !void {
    var element = try parser.next();

    // Make sure the element is not null
    try std.testing.expect(element != null);

    try std.testing.expectEqualStrings("property", @tagName(element.?));

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

    try std.testing.expectEqualStrings("argument", @tagName(element.?));

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
        try std.testing.expectEqual(@as(i64, @intCast(expected)), value.integer);
    } else if (type_info == .Float or type_info == .ComptimeFloat) {
        try std.testing.expect(value == .decimal);
        try std.testing.expectEqual(@as(f64, @floatCast(expected)), value.decimal);
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

test "Multiline comments between node and value" {
    var allocator = std.testing.allocator;

    var parser = try Parser.init(
        \\ node /* comment */ "arg"
    );

    try expectNodeBegin(&parser, allocator, "node", null);
    try expectArgument(&parser, allocator, "arg", null);
    try expectNodeEnd(&parser);
    try expectNull(&parser);
}
