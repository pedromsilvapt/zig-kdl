const std = @import("std");
const assert = std.debug.assert;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const utf8 = @import("./reader.zig").utf8;
const Reader = @import("./reader.zig").Reader;
const Location = @import("./reader.zig").Location;
const CodePoint = @import("./reader.zig").CodePoint;
const Matcher = @import("./matchers.zig").Matcher;

pub const TokenKind = union(enum) {
    // Text
    bare_identifier,
    raw_string,
    escaped_string,
    // Numbers
    decimal,
    signed_integer,
    hex,
    octal,
    binary,
    keyword,
    // Symbols
    brace_open,
    brace_close,
    semicolon,
    curly_brace_open,
    curly_brace_close,
    equals,
    // White spaces
    newline,
    ws,
    single_line_comment,
    escline,
    // End of file
    eof,
};

pub const Token = struct {
    kind: TokenKind,
    text: []const u8,
    location_start: Location = .{},
    location_end: Location = .{},

    const escaped_codes = "\\/bfnrt";
    const escaped_replacements = "\\/\x08\x0C\n\r\t";

    pub fn toString(self: *const Token, allocator: Allocator) ![]u8 {
        assert(self.kind == .bare_identifier or self.kind == .raw_string or self.kind == .escaped_string);

        var buffer = ArrayList(u8).init(allocator);
        errdefer buffer.deinit();

        if (self.kind == .bare_identifier) {
            // Allocate exactly as much memory is required for this
            try buffer.ensureTotalCapacityPrecise(self.text.len);
            // Even though the memory is allocated, the items buffer is still
            // len == 0. We expand it (uninitialized) to it's total capacity
            buffer.expandToCapacity();

            std.mem.copy(u8, buffer.items, self.text);
        } else if (self.kind == .raw_string) {
            // Assume that the text follows the following pattern:
            // r##"foo"##. The name of # at the end of the string must match
            // the number of # at the start. They can be zero or more.

            // Skip the first char always (it's an 'r')
            var i: usize = 1;

            // Simple loop just to increase the value of i
            while (i < self.text.len and self.text[i] == '#') : (i += 1) {}

            // Increase one more for the mandatory quote " character
            i += 1;

            const start = i;
            const end = self.text.len - (i - 1);

            const inner_text = self.text[start..end];

            // Allocate exactly as much memory is required for this
            try buffer.ensureTotalCapacityPrecise(inner_text.len);
            // Even though the memory is allocated, the items buffer is still
            // len == 0. We expand it (uninitialized) to it's total capacity
            buffer.expandToCapacity();

            std.mem.copy(u8, buffer.items, inner_text);
        } else if (self.kind == .escaped_string) {
            // We copy contiguous chunks of non-escaped characters all at once to improve performance
            // Here in this variable we save the start position of the current chunk
            // So when we find an escaped character, we can write all characters
            // starting from this position to the buffer
            var last_chunk_start: usize = 1;

            var i: usize = 1;
            while (i < self.text.len - 1) : (i += 1) {
                // Detect escaped characters ()
                if (self.text[i] == '\\') {
                    if (last_chunk_start < i) {
                        try buffer.appendSlice(self.text[last_chunk_start..i]);
                    }

                    if (i < self.text.len - 2) {
                        if (indexOfChar(escaped_codes, self.text[i + 1])) |index| {
                            // Replace the string representations os "\n", "\t", etc...
                            // by their actual values
                            try buffer.append(escaped_replacements[index]);

                            // In this case, we must increment the character by one more
                            i += 1;

                            last_chunk_start = i + 1;
                        } else if (self.text[i + 1] == 'u') {
                            // Replace unicode escape characters with the format
                            // "u{X}", where X can be anywhere from 1 to 6 hex
                            // characters

                            // The index of the next '}' character in the string
                            var j = indexOfCharAfter(self.text, i + 3, '}') orelse unreachable;

                            // Contains the string X betwen the "u{X}". Length can be
                            // between 1 and 6
                            var input_buffer = self.text[i + 3 .. j];

                            // Parses the string as an hexadecimal integer (u21)
                            var code_point = try std.fmt.parseInt(CodePoint, input_buffer, 16);

                            // Array with at least 4 positions, where we will store the decoded
                            // utf8 codepoint
                            var output_buffer = [_]u8{ 0, 0, 0, 0 };

                            var output_length = try std.unicode.utf8Encode(code_point, &output_buffer);

                            try buffer.appendSlice(output_buffer[0..output_length]);

                            // Advance the cursors
                            i = j;
                            last_chunk_start = j + 1;
                        }
                    }
                } else if (i == self.text.len - 2) {
                    // If this is the last character, make sure we flush any chunks
                    // we need to copy to the buffer
                    if (last_chunk_start <= i) {
                        try buffer.appendSlice(self.text[last_chunk_start .. i + 1]);
                    }
                }
            }
        } else {
            unreachable;
        }

        return buffer.toOwnedSlice();
    }

    pub fn toDecimal(self: *const Token) !f64 {
        if (self.kind == .decimal) {
            return try std.fmt.parseFloat(f64, self.text);
        } else {
            unreachable;
        }
    }

    pub fn toInteger(self: *const Token) !i64 {
        if (self.kind == .signed_integer or
            self.kind == .hex or
            self.kind == .octal or
            self.kind == .binary)
        {
            // Radix 0 means the radix is auto-detected based on the prefix 0x, 0o, or 0b
            return try std.fmt.parseInt(i64, self.text, 0);
        } else {
            unreachable;
        }
    }

    pub fn toScalar(self: *const Token, allocator: Allocator) !Scalar {
        if (self.kind == .raw_string or self.kind == .escaped_string) {
            return Scalar{ .string = try self.toString(allocator) };
        } else if (self.kind == .decimal) {
            return Scalar{ .decimal = try self.toDecimal() };
        } else if (self.kind == .signed_integer or
            self.kind == .hex or
            self.kind == .octal or
            self.kind == .binary)
        {
            return Scalar{ .integer = try self.toInteger() };
        } else if (self.kind == .keyword) {
            if (std.mem.eql(u8, self.text, "true")) {
                return Scalar{ .boolean = true };
            } else if (std.mem.eql(u8, self.text, "false")) {
                return Scalar{ .boolean = false };
            } else if (std.mem.eql(u8, self.text, "null")) {
                return Scalar{ .none = {} };
            } else {
                return error.InvalidScalarToken;
            }
        } else {
            return error.InvalidScalarToken;
        }
    }

    pub fn deinitFromScalar(self: *const Token, allocator: Allocator) void {
        if (self.kind == .escaped_string or self.kind == .raw_string or self.kind == .signed_integer or self.kind == .decimal) {
            allocator.free(self.text);
        }
    }

    pub fn fromScalar(allocator: Allocator, scalar: Scalar) !Token {
        switch (scalar) {
            .string => |str| {
                // TODO Implement escaping, unicode characters, etc...
                // Wrap the string in double quotes
                const str_str = try std.fmt.allocPrint(allocator, "\"{s}\"", .{str});
                errdefer allocator.free(str_str);

                return Token { .kind = .escaped_string, .text = str_str };
            },
            .integer => |int| {
                // Convert the integer to string
                const int_str = try std.fmt.allocPrint(allocator, "{d}", .{int});
                errdefer allocator.free(int_str);

                return Token { .kind = .signed_integer, .text = int_str };
            },
            .decimal => |dec| {
                // Convert the decimal to string
                const dec_str = try std.fmt.allocPrint(allocator, "{d}", .{dec});
                errdefer allocator.free(dec_str);

                return Token { .kind = .decimal, .text = dec_str };
            },
            .boolean => |bit| {
                return Token { .kind = .keyword, .text = if (bit) "true" else "false" };
            },
            .none => {
                return Token { .kind = .keyword, .text = "none" };
            }
        }
    }

    pub const Scalar = union(enum) {
        string: []const u8,
        integer: i64,
        decimal: f64,
        boolean: bool,
        none: void,

        pub fn deinit(self: *Scalar, allocator: Allocator) void {
            if (self.* == .string) {
                allocator.free(self.string);
            }
        }
    };
};

pub const TokenMatchers = struct {
    // bare-identifier := (
    //      (identifier-char - digit - sign) identifier-char*
    //  |
    //      sign ((identifier-char - digit) identifier-char*)?
    //  ) - keyword
    pub const bare_identifier = Matcher.oneOf(.{
        Matcher.sequence(.{
            Matcher.sequence(.{
                Matcher.digit(.decimal).negate(),
                sign.negate(),
                identifier_char,
            }),
            identifier_char.repeat(.{}),
        }),
        Matcher.sequence(.{
            sign,
            Matcher.sequence(.{
                Matcher.sequence(.{
                    Matcher.digit(.decimal).negate(),
                    identifier_char,
                }),
                identifier_char.repeat(.{}),
            }).optional(),
        }),
    }).except(.{keyword}, .full);

    // identifier-char := unicode - linespace - [\/(){}<>;[]=,"]
    pub const identifier_char = Matcher.sequence(.{
        linespace.negate(),
        Matcher.oneOfChars("\\/(){}<>;[]=,\"").negate(),
        Matcher.any(), // TODO unicode
    });

    // keyword := boolean | 'null'
    pub const keyword = Matcher.oneOf(.{
        boolean,
        Matcher.string("null"),
    });

    // signed_integer := sign? integer
    pub const signed_integer = Matcher.sequence(.{
        sign.optional(),
        integer,
    });

    // decimal := sign? integer ('.' integer)? exponent?
    pub const decimal = Matcher.sequence(.{
        sign.optional(),
        integer,
        Matcher.char('.'),
        integer,
        exponent.optional(),
    });

    // exponent := ('e' | 'E') sign? integer
    pub const exponent = Matcher.sequence(.{
        Matcher.oneOf(.{
            Matcher.char('e'),
            Matcher.char('E'),
        }),
        sign.optional(),
        integer,
    });

    // integer := digit (digit | '_')*
    pub const integer = Matcher.sequence(.{
        Matcher.digit(.decimal),
        Matcher.oneOf(.{
            Matcher.digit(.decimal),
            Matcher.char('_'),
        }).repeat(.{}),
    });

    // sign := '+' | '-'
    pub const sign = Matcher.oneOf(.{
        Matcher.char('+'),
        Matcher.char('-'),
    });

    // hex := sign? '0x' hex-digit (hex-digit | '_')*
    pub const hex = Matcher.sequence(.{
        sign.optional(),
        Matcher.string("0x"),
        Matcher.digit(.hex),
        Matcher.oneOf(.{
            Matcher.digit(.hex),
            Matcher.char('_'),
        }).repeat(.{}),
    });

    // octal := sign? '0o' [0-7] [0-7_]*
    pub const octal = Matcher.sequence(.{
        sign.optional(),
        Matcher.string("0o"),
        Matcher.digit(.octal),
        Matcher.oneOf(.{
            Matcher.digit(.octal),
            Matcher.char('_'),
        }).repeat(.{}),
    });

    // binary := sign? '0b' ('0' | '1') ('0' | '1' | '_')*
    pub const binary = Matcher.sequence(.{
        sign.optional(),
        Matcher.string("0b"),
        Matcher.digit(.binary),
        Matcher.oneOf(.{
            Matcher.digit(.binary),
            Matcher.char('_'),
        }).repeat(.{}),
    });

    // boolean := 'true' | 'false'
    pub const boolean = Matcher.oneOf(.{
        Matcher.string("true"),
        Matcher.string("false"),
    });

    // escline := '\\' ws* (single-line-comment | newline)
    pub const escline = Matcher.sequence(.{
        Matcher.char('\\'),
        ws.repeat(.{}),
        Matcher.oneOf(.{
            single_line_comment,
            newline,
        }),
    });

    // linespace := newline | ws | single-line-comment
    pub const linespace = Matcher.oneOf(.{
        newline,
        ws,
        single_line_comment,
    });

    // newline := See Table (All line-break white_space)
    pub const newline = Matcher.newline();

    // ws := bom | unicode-space | multi-line-comment
    pub const ws = Matcher.oneOf(.{ bom, unicode_space, multi_line_comment });

    // bom := '\u{FEFF}'
    pub const bom = Matcher.codepoint(0xFEFF);

    // unicode-space := See Table (All White_Space unicode characters which are not `newline`)
    pub const unicode_space = Matcher.whitespace();

    // single-line-comment := '//' ^newline+ (newline | eof)
    pub const single_line_comment = Matcher.sequence(.{
        Matcher.string("//"),
        Matcher.sequence(.{
            newline.negate(),
            Matcher.any(),
        }).atLeastOnce(),
        // Matcher.oneOf(.{
        //     newline,
        //     Matcher.eof(),
        // }),
    });

    // multi-line-comment := '/*' commented-block
    // commented-block := '*/' | (multi-line-comment | '*' | '/' | [^*/]+) commented-block
    pub const multi_line_comment = Matcher.sequence(.{
        Matcher.string("/*"),
        Matcher.sequence(.{
            Matcher.string("*/").negate(),
            Matcher.oneOf(.{
                Matcher.ref(@This(), .multi_line_comment),
                Matcher.any(),
            }),
        }).repeat(.{}),
        Matcher.string("*/"),
    });

    // equals := '='
    pub const equals = Matcher.char('=');

    // semicolon := ';'
    pub const semicolon = Matcher.char(';');

    // brace-open := '('
    pub const brace_open = Matcher.char('(');

    // brace-close := ')'
    pub const brace_close = Matcher.char(')');

    // curly-brace-open := '{'
    pub const curly_brace_open = Matcher.char('{');

    // curly-brace-close := '}'
    pub const curly_brace_close = Matcher.char('}');

    // eof :=
    pub const eof = Matcher.eof();

    // escaped-string := '"' character* '"'
    pub const escaped_string = Matcher.sequence(.{
        Matcher.char('"'),
        character.repeat(.{}),
        Matcher.char('"'),
    });

    // character := '\' escape | [^\"]
    pub const character = Matcher.oneOf(.{
        Matcher.sequence(.{
            Matcher.char('\\'),
            escape,
        }),
        Matcher.sequence(.{
            Matcher.char('"').negate(),
            Matcher.any(),
        }),
    });

    // escape := ["\\/bfnrt] | 'u{' hex-digit{1, 6} '}'
    pub const escape = Matcher.oneOf(.{
        Matcher.oneOfChars("\"\\/bfnrt"),
        Matcher.sequence(.{
            Matcher.string("u{"),
            Matcher.digit(.hex).repeat(.{ .min = 1, .max = 6 }),
            Matcher.string("}"),
        }),
    });

    // raw-string := 'r' raw-string-hash
    // raw-string-hash := '#' raw-string-hash '#' | raw-string-quotes
    // raw-string-quotes := '"' .* '"'
    pub const raw_string = Matcher.rawQuotedString();
};

pub const Tokenizer = struct {
    reader: Reader,

    location_start: Location = .{},

    pub fn init(source: []const u8) !Tokenizer {
        return Tokenizer{
            .reader = try Reader.init(source),
        };
    }

    pub fn next(self: *Tokenizer) !?Token {
        while (self.reader.state != .eof) {
            if (self.match(TokenMatchers.eof)) {
                return self.createToken(.eof);
            }

            if (self.match(TokenMatchers.ws)) {
                return self.createToken(.ws);
            }

            if (self.match(TokenMatchers.newline)) {
                return self.createToken(.newline);
            }

            if (self.match(TokenMatchers.single_line_comment)) {
                return self.createToken(.single_line_comment);
            }

            if (self.match(TokenMatchers.escline)) {
                return self.createToken(.escline);
            }

            if (self.match(TokenMatchers.equals)) {
                return self.createToken(.equals);
            }

            if (self.match(TokenMatchers.curly_brace_open)) {
                return self.createToken(.curly_brace_open);
            }

            if (self.match(TokenMatchers.curly_brace_close)) {
                return self.createToken(.curly_brace_close);
            }

            if (self.match(TokenMatchers.brace_open)) {
                return self.createToken(.brace_open);
            }

            if (self.match(TokenMatchers.brace_close)) {
                return self.createToken(.brace_close);
            }

            if (self.match(TokenMatchers.semicolon)) {
                return self.createToken(.semicolon);
            }

            if (self.match(TokenMatchers.binary)) {
                return self.createToken(.binary);
            }

            if (self.match(TokenMatchers.octal)) {
                return self.createToken(.octal);
            }

            if (self.match(TokenMatchers.hex)) {
                return self.createToken(.hex);
            }

            if (self.match(TokenMatchers.decimal)) {
                return self.createToken(.decimal);
            }

            if (self.match(TokenMatchers.signed_integer)) {
                return self.createToken(.signed_integer);
            }

            if (self.match(TokenMatchers.raw_string)) {
                return self.createToken(.raw_string);
            }

            if (self.match(TokenMatchers.bare_identifier)) {
                return self.createToken(.bare_identifier);
            }

            if (self.match(TokenMatchers.escaped_string)) {
                return self.createToken(.escaped_string);
            }

            if (self.match(TokenMatchers.keyword)) {
                return self.createToken(.keyword);
            }

            return error.InvalidToken;
        }

        return null;
    }

    fn match(self: *Tokenizer, matcher: anytype) bool {
        var reader = self.reader;

        if (matcher.match(&reader)) {
            self.reader = reader;

            return true;
        }

        return false;
    }

    fn raiseError(self: *Tokenizer, message: []const u8) !void {
        _ = self;
        _ = message;

        return error.TokenizerError;
    }

    fn createToken(self: *Tokenizer, kind: TokenKind) Token {
        var location_start = self.location_start;
        defer self.location_start = self.reader.location;

        var location_end = self.reader.location;

        return .{
            .kind = kind,
            .text = self.reader.getText(location_start, location_end),
            .location_start = location_start,
            .location_end = location_end,
        };
    }
};

fn indexOfChar(haystack: []const u8, needle: u8) ?usize {
    var result: ?usize = null;

    var i: usize = 0;
    while (i < haystack.len) : (i += 1) {
        if (haystack[i] == needle) {
            result = i;
            break;
        }
    }

    return result;
}

fn indexOfCharAfter(haystack: []const u8, start: usize, needle: u8) ?usize {
    if (indexOfChar(haystack[start..], needle)) |index| {
        return index + start;
    }

    return null;
}

test "Multi line comment matcher" {
    var reader = try Reader.init("/* foo */");

    try std.testing.expectEqual(true, TokenMatchers.multi_line_comment.match(&reader));
    try std.testing.expectEqual(@as(usize, 9), reader.location.offset);

    reader = try Reader.init("/* /* foo */ /* bar */ hi */");
    try std.testing.expectEqual(true, TokenMatchers.multi_line_comment.match(&reader));
    try std.testing.expectEqual(@as(usize, 28), reader.location.offset);

    // Should fail, missing a closing slash
    reader = try Reader.init("/* /* foo * */");
    try std.testing.expectEqual(false, TokenMatchers.multi_line_comment.match(&reader));
    try std.testing.expectEqual(@as(usize, 14), reader.location.offset);
}

test "Signed integer matcher" {
    var reader = try Reader.init("+105_00");

    try std.testing.expectEqual(true, TokenMatchers.signed_integer.match(&reader));
    try std.testing.expectEqual(@as(usize, 7), reader.location.offset);

    reader = try Reader.init("+1");
    try std.testing.expectEqual(true, TokenMatchers.signed_integer.match(&reader));
    try std.testing.expectEqual(@as(usize, 2), reader.location.offset);

    reader = try Reader.init("105_00");
    try std.testing.expectEqual(true, TokenMatchers.signed_integer.match(&reader));
    try std.testing.expectEqual(@as(usize, 6), reader.location.offset);
}

fn expectToken(tokenizer: *Tokenizer, kind: TokenKind, text: []const u8) !void {
    const token = try tokenizer.next();

    try std.testing.expect(token != null);
    try std.testing.expectEqual(kind, token.?.kind);
    try std.testing.expectEqualStrings(text, token.?.text);
}

fn expectNTokens(tokenizer: *Tokenizer, n: usize, kind: TokenKind, text: []const u8) !void {
    var i: usize = 0;
    while (i < n) : (i += 1) {
        try expectToken(tokenizer, kind, text);
    }
}

test "Read tokens" {
    var tokenizer = try Tokenizer.init(
        \\node bool=true int=1 decimal=1.5 str="foobar" {
        \\  values false null 1 1.5 "foobar"
        \\}
    );

    // node bool=true
    try expectToken(&tokenizer, .bare_identifier, "node");
    try expectToken(&tokenizer, .ws, " ");
    try expectToken(&tokenizer, .bare_identifier, "bool");
    try expectToken(&tokenizer, .equals, "=");
    try expectToken(&tokenizer, .keyword, "true");
    try expectToken(&tokenizer, .ws, " ");
    // int=1 decimal=1.5
    try expectToken(&tokenizer, .bare_identifier, "int");
    try expectToken(&tokenizer, .equals, "=");
    try expectToken(&tokenizer, .signed_integer, "1");
    try expectToken(&tokenizer, .ws, " ");
    try expectToken(&tokenizer, .bare_identifier, "decimal");
    try expectToken(&tokenizer, .equals, "=");
    try expectToken(&tokenizer, .decimal, "1.5");
    try expectToken(&tokenizer, .ws, " ");
    // str="foobar" {
    try expectToken(&tokenizer, .bare_identifier, "str");
    try expectToken(&tokenizer, .equals, "=");
    try expectToken(&tokenizer, .escaped_string, "\"foobar\"");
    try expectToken(&tokenizer, .ws, " ");
    try expectToken(&tokenizer, .curly_brace_open, "{");
    try expectToken(&tokenizer, .newline, "\n");
    //   values false null
    try expectNTokens(&tokenizer, 2, .ws, " ");
    try expectToken(&tokenizer, .bare_identifier, "values");
    try expectToken(&tokenizer, .ws, " ");
    try expectToken(&tokenizer, .keyword, "false");
    try expectToken(&tokenizer, .ws, " ");
    try expectToken(&tokenizer, .keyword, "null");
    try expectToken(&tokenizer, .ws, " ");
    // 1 1.5 "foobar"
    try expectToken(&tokenizer, .signed_integer, "1");
    try expectToken(&tokenizer, .ws, " ");
    try expectToken(&tokenizer, .decimal, "1.5");
    try expectToken(&tokenizer, .ws, " ");
    try expectToken(&tokenizer, .escaped_string, "\"foobar\"");
    try expectToken(&tokenizer, .newline, "\n");
    // }
    try expectToken(&tokenizer, .curly_brace_close, "}");
    try expectToken(&tokenizer, .eof, "");
}

test "Read tokens identifiers vs keywords" {
    var tokenizer = try Tokenizer.init(
        \\bare trueId=true falseId=false nullId=null "true"=false
    );

    // bare trueId=true
    try expectToken(&tokenizer, .bare_identifier, "bare");
    try expectToken(&tokenizer, .ws, " ");
    try expectToken(&tokenizer, .bare_identifier, "trueId");
    try expectToken(&tokenizer, .equals, "=");
    try expectToken(&tokenizer, .keyword, "true");
    try expectToken(&tokenizer, .ws, " ");
    // falseId=false nullId=null
    try expectToken(&tokenizer, .bare_identifier, "falseId");
    try expectToken(&tokenizer, .equals, "=");
    try expectToken(&tokenizer, .keyword, "false");
    try expectToken(&tokenizer, .ws, " ");
    try expectToken(&tokenizer, .bare_identifier, "nullId");
    try expectToken(&tokenizer, .equals, "=");
    try expectToken(&tokenizer, .keyword, "null");
    try expectToken(&tokenizer, .ws, " ");
    // "true"=false
    try expectToken(&tokenizer, .escaped_string, "\"true\"");
    try expectToken(&tokenizer, .equals, "=");
    try expectToken(&tokenizer, .keyword, "false");
    try expectToken(&tokenizer, .eof, "");
}

fn expectTokenString(allocator: Allocator, src: []const u8, expected: []const u8) !void {
    var token = Token{
        .kind = .escaped_string,
        .text = src,
        .location_start = .{},
        .location_end = .{},
    };

    var string = try token.toString(allocator);
    defer allocator.free(string);

    try std.testing.expectEqualStrings(expected, string);
}

fn expectTokenRawString(allocator: Allocator, src: []const u8, expected: []const u8) !void {
    var token = Token{
        .kind = .raw_string,
        .text = src,
        .location_start = .{},
        .location_end = .{},
    };

    var string = try token.toString(allocator);
    defer allocator.free(string);

    try std.testing.expectEqualStrings(expected, string);
}

test "Token toString" {
    var allocator = std.testing.allocator;

    try expectTokenString(allocator, "\"foo\"", "foo");
    try expectTokenString(allocator, "\"foo\\nbar\"", "foo\nbar");
    try expectTokenString(allocator, "\"foo\\r\\nbar\\\\\"", "foo\r\nbar\\");
    try expectTokenString(allocator, "\"\"", "");
    try expectTokenString(allocator, "\"\\n\"", "\n");
    try expectTokenString(allocator, "\"\\u{1f4a9}\"", "\u{1f4a9}");
    try expectTokenRawString(allocator, "r##\"foo \" \" bar\"##", "foo \" \" bar");
    try expectTokenRawString(allocator, "r##\"\"##", "");
    try expectTokenRawString(allocator, "r#\"\"#", "");
    try expectTokenRawString(allocator, "r#\"a\"#", "a");
    try expectTokenRawString(allocator, "r\"\"", "");
    try expectTokenRawString(allocator, "r\"a\"", "a");
}

/// Utility function, prints the code to generate assertions for a given tokenizer
fn printExpectedTokens(tokenizer: *Tokenizer) void {
    while (true) {
        if (try tokenizer.next()) |token| {
            std.debug.print("\ntry expectToken(&tokenizer, .{s}, \"{s}\");", .{
                @tagName(token.kind),
                token.text,
            });
        } else {
            break;
        }
    }
    std.debug.print("\n", .{});
}
