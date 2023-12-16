const std = @import("std");
const Utf8View = std.unicode.Utf8View;
const Utf8Iterator = std.unicode.Utf8Iterator;

pub const CodePoint = u21;

pub const Reader = struct {
    uft8_iterator: Utf8Iterator,
    location: Location = .{},
    state: State = .bof,

    pub const State = enum {
        /// Beginning of File
        bof,

        /// Middle of line
        mol,

        /// End of line
        eol,

        /// End of file
        eof,
    };

    pub fn init(source: []const u8) !Reader {
        return Reader{
            .uft8_iterator = (try Utf8View.init(source)).iterator(),
        };
    }

    pub fn next(self: *Reader) ?CodePoint {
        // Get the next code point. Note that in UTF8, each code point may take up
        // more than just one byte, and that means that while our `column`
        // field only increases by 1 at a time,
        if (self.uft8_iterator.nextCodepointSlice()) |code_point_slice| {
            var code_point = std.unicode.utf8Decode(code_point_slice) catch unreachable;

            self.location.offset += code_point_slice.len;

            if (utf8.isCarriageReturn(code_point)) {
                if (self.peek()) |next_code_point| {
                    self.state = switch (utf8.isLineFeed(next_code_point)) {
                        true => .mol,
                        false => .eol,
                    };
                } else {
                    self.state = .eof;
                }
            } else if (utf8.isNewLine(code_point)) {
                self.state = .eol;
            } else {
                self.state = .mol;
            }

            if (self.state == .eol) {
                self.location.line += 1;
                self.location.column = 0;
            }

            if (!utf8.isNewLine(code_point)) {
                self.location.column += 1;
            }

            return code_point;
        } else {
            self.state = .eof;

            return null;
        }
    }

    pub fn peek(self: *Reader) ?CodePoint {
        const code_point_slice = self.uft8_iterator.peek(1);

        if (code_point_slice.len == 0) {
            return null;
        }

        return std.unicode.utf8Decode(code_point_slice) catch unreachable;
    }

    pub fn skip(self: *Reader, amount: usize) void {
        var i: usize = 0;
        while (i < amount) : (i += 1) {
            if (self.next() == null) break;
        }
    }

    pub fn getText(self: *const Reader, location_start: Location, location_end: Location) []const u8 {
        return self.uft8_iterator.bytes[location_start.offset..location_end.offset];
    }

    pub fn reset(self: *Reader) void {
        self.uft8_iterator.i = 0;
        self.location = .{};
    }
};

pub const utf8 = struct {
    pub fn fromASCII(char: u8) CodePoint {
        return @as(CodePoint, @intCast(char));
    }

    pub fn isWhiteSpace(char: CodePoint) bool {
        return char == 0x0009 or // Character Tabulation
            char == 0x0020 or // Space
            char == 0x00A0 or // No-Break Space
            char == 0x1680 or // Orgham Space Mark
            char == 0x2000 or // En Quad
            char == 0x2001 or // Em Quad
            char == 0x2002 or // En Space
            char == 0x2003 or // Em Space
            char == 0x2004 or // Three-Per-Em Space
            char == 0x2005 or // Four-Per-Em Space
            char == 0x2006 or // Six-Per-Em Space
            char == 0x2007 or // Figure Space
            char == 0x2008 or // Punctuation Space
            char == 0x2009 or // Thin Space
            char == 0x200A or // Hair Space
            char == 0x202F or // Narrow No-Break Space
            char == 0x205F or // Medium Mathematical Space
            char == 0x3000; // Ideographic Space
    }

    pub fn isBinaryDigit(char: CodePoint) bool {
        return char == 0x0030 or char == 0x0031; // [0-1]
    }

    pub fn isOctalDigit(char: CodePoint) bool {
        return char >= 0x0030 and char <= 0x0037; // [0-7]
    }

    pub fn isDecimalDigit(char: CodePoint) bool {
        return char >= 0x0030 and char <= 0x0039; // [0-9]
    }

    pub fn isHexDigit(char: CodePoint) bool {
        return (char >= 0x0030 and char <= 0x0039) // [0-9]
        or (char >= 0x0041 and char <= 0x0046) // [A-F]
        or (char >= 0x0061 and char <= 0x0066); // [a-f]
    }

    pub fn isCarriageReturn(char: CodePoint) bool {
        return char == 0x000D;
    }

    pub fn isLineFeed(char: CodePoint) bool {
        return char == 0x000A;
    }

    pub fn isNewLine(char: CodePoint) bool {
        return char == 0x000D or // Carriage Return
            char == 0x000A or // Line Feed
            char == 0x0085 or // Next Line
            char == 0x000C or // Form Feed
            char == 0x2028 or // Line Separator
            char == 0x2029; // Paragraph Separator
    }
};

pub const Location = struct {
    line: usize = 0,
    column: usize = 0,
    offset: usize = 0,
};

fn expectReadCodePoint(reader: *Reader, expected: []const u8, offset: usize, line: usize, column: usize) !void {
    const location_start = reader.location;
    _ = reader.next();
    const location_end = reader.location;

    try std.testing.expectEqual(offset, reader.location.offset);
    try std.testing.expectEqual(line, reader.location.line);
    try std.testing.expectEqual(column, reader.location.column);
    try std.testing.expectEqualStrings(expected, reader.getText(location_start, location_end));
}

test "Reader updates location field correctly" {
    var reader = try Reader.init("node {}");

    // Test the reader starts at the beginning
    try std.testing.expectEqual(@as(Reader.State, .bof), reader.state);

    try expectReadCodePoint(&reader, "n", 1, 0, 1);
    try std.testing.expectEqual(@as(Reader.State, .mol), reader.state);
    try expectReadCodePoint(&reader, "o", 2, 0, 2);
    try std.testing.expectEqual(@as(Reader.State, .mol), reader.state);
    try expectReadCodePoint(&reader, "d", 3, 0, 3);
    try std.testing.expectEqual(@as(Reader.State, .mol), reader.state);
    try expectReadCodePoint(&reader, "e", 4, 0, 4);
    try std.testing.expectEqual(@as(Reader.State, .mol), reader.state);
    try expectReadCodePoint(&reader, " ", 5, 0, 5);
    try std.testing.expectEqual(@as(Reader.State, .mol), reader.state);
    try expectReadCodePoint(&reader, "{", 6, 0, 6);
    try std.testing.expectEqual(@as(Reader.State, .mol), reader.state);
    try expectReadCodePoint(&reader, "}", 7, 0, 7);
    try std.testing.expectEqual(@as(Reader.State, .mol), reader.state);
    try std.testing.expectEqual(@as(?CodePoint, null), reader.next());
    try std.testing.expectEqual(@as(Reader.State, .eof), reader.state);
}

test "Reader multi-line updates location field correctly" {
    var reader = try Reader.init("no\nde \r\n{\n\n }");

    // Test the reader starts at the beginning
    try std.testing.expectEqual(@as(Reader.State, .bof), reader.state);

    try expectReadCodePoint(&reader, "n", 1, 0, 1);
    try std.testing.expectEqual(@as(Reader.State, .mol), reader.state);
    try expectReadCodePoint(&reader, "o", 2, 0, 2);
    try std.testing.expectEqual(@as(Reader.State, .mol), reader.state);
    try expectReadCodePoint(&reader, "\n", 3, 1, 0);
    try std.testing.expectEqual(@as(Reader.State, .eol), reader.state);
    try expectReadCodePoint(&reader, "d", 4, 1, 1);
    try std.testing.expectEqual(@as(Reader.State, .mol), reader.state);
    try expectReadCodePoint(&reader, "e", 5, 1, 2);
    try std.testing.expectEqual(@as(Reader.State, .mol), reader.state);
    try expectReadCodePoint(&reader, " ", 6, 1, 3);
    try std.testing.expectEqual(@as(Reader.State, .mol), reader.state);
    try expectReadCodePoint(&reader, "\r", 7, 1, 3);
    try std.testing.expectEqual(@as(Reader.State, .mol), reader.state);
    try expectReadCodePoint(&reader, "\n", 8, 2, 0);
    try std.testing.expectEqual(@as(Reader.State, .eol), reader.state);
    try expectReadCodePoint(&reader, "{", 9, 2, 1);
    try std.testing.expectEqual(@as(Reader.State, .mol), reader.state);
    try expectReadCodePoint(&reader, "\n", 10, 3, 0);
    try std.testing.expectEqual(@as(Reader.State, .eol), reader.state);
    try expectReadCodePoint(&reader, "\n", 11, 4, 0);
    try std.testing.expectEqual(@as(Reader.State, .eol), reader.state);
    try expectReadCodePoint(&reader, " ", 12, 4, 1);
    try std.testing.expectEqual(@as(Reader.State, .mol), reader.state);
    try expectReadCodePoint(&reader, "}", 13, 4, 2);
    try std.testing.expectEqual(@as(Reader.State, .mol), reader.state);
    try std.testing.expectEqual(@as(?CodePoint, null), reader.next());
    try std.testing.expectEqual(@as(Reader.State, .eof), reader.state);
}
