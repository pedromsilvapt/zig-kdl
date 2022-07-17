//! Matchers receive a reader (a structure similar to an iterator of UTF8 codepoits)
//! and should return true or false in case they match the reader.
//! Standard operating procedure should be that a matcher should mutate the reader's
//! position as it advances. And if it fails to match, the reader should be left
//! on the position that fail.
//! Certain matchers can be composed with other matchers, such as the optional matcher.
//! In those cases, obviously, even if the child matcher fails, so long as the
//! parent matcher succeeds, the reader's position should take that into account.

const std = @import("std");
const Reader = @import("./reader.zig").Reader;
const CodePoint = @import("./reader.zig").CodePoint;
const utf8 = @import("./reader.zig").utf8;

pub const Matcher = struct {
    pub fn eof() EofMatcher {
        return EofMatcher{};
    }

    pub fn any() AnyMatcher {
        return AnyMatcher{};
    }

    pub fn whitespace() WhitespaceMatcher {
        return WhitespaceMatcher{};
    }

    pub fn newline() NewlineMatcher {
        return NewlineMatcher{};
    }

    pub fn digit(system: NumericSystem) DigitMatcher {
        return DigitMatcher{ .system = system };
    }

    pub fn rawQuotedString() RawQuotedStringMatcher {
        return RawQuotedStringMatcher{};
    }

    pub fn oneOf(alternatives: anytype) OneOfMatcher(@TypeOf(alternatives)) {
        return OneOfMatcher(@TypeOf(alternatives)){ .alternative_matchers = alternatives };
    }

    pub fn sequence(segments: anytype) SequenceMatcher(@TypeOf(segments)) {
        return SequenceMatcher(@TypeOf(segments)){ .segment_matchers = segments };
    }

    pub fn ref(comptime Type: type, comptime matcher_name: anytype) RefMatcher(Type, matcher_name) {
        return RefMatcher(Type, matcher_name){};
    }

    pub fn codepoint(expected_codepoint: CodePoint) CodePointMatcher {
        return CodePointMatcher{ .codepoint = expected_codepoint };
    }

    pub fn char(expected_char: u8) CharMatcher {
        return CharMatcher{ .char = expected_char };
    }

    pub fn string(expected_string: []const u8) StringMatcher {
        return StringMatcher{ .string = expected_string };
    }

    pub fn oneOfChars(expected_string: []const u8) OneOfCharsMatcher {
        return OneOfCharsMatcher{ .string = expected_string };
    }
};

pub fn RefMatcher(comptime Type: type, comptime matcher_name: anytype) type {
    return struct {
        pub fn match(self: *const @This(), reader: *Reader) bool {
            _ = self;

            return @field(Type, @tagName(matcher_name)).match(reader);
        }

        pub usingnamespace MatcherModifiers;
    };
}

pub const EofMatcher = struct {
    pub fn match(self: *const EofMatcher, reader: *Reader) bool {
        _ = self;

        return reader.next() == null;
    }

    pub usingnamespace MatcherModifiers;
};

pub const AnyMatcher = struct {
    pub fn match(self: *const AnyMatcher, reader: *Reader) bool {
        _ = self;

        return reader.next() != null;
    }

    pub usingnamespace MatcherModifiers;
};

pub const WhitespaceMatcher = struct {
    pub fn match(self: *const WhitespaceMatcher, reader: *Reader) bool {
        _ = self;

        var result = false;

        if (reader.next()) |char| {
            result = utf8.isWhiteSpace(char);
        }

        return result;
    }

    pub usingnamespace MatcherModifiers;
};

pub const NewlineMatcher = struct {
    pub fn match(self: *const NewlineMatcher, reader: *Reader) bool {
        _ = self;

        var result = false;

        if (reader.next()) |char| {
            result = utf8.isNewLine(char);
        }

        return result;
    }

    pub usingnamespace MatcherModifiers;
};

pub const NumericSystem = enum {
    binary,
    octal,
    decimal,
    hex,
};

pub const DigitMatcher = struct {
    system: NumericSystem,

    pub fn match(self: *const DigitMatcher, reader: *Reader) bool {
        _ = self;

        var result = false;

        if (reader.next()) |char| {
            if (self.system == .binary) {
                result = utf8.isBinaryDigit(char);
            } else if (self.system == .octal) {
                result = utf8.isOctalDigit(char);
            } else if (self.system == .decimal) {
                result = utf8.isDecimalDigit(char);
            } else if (self.system == .hex) {
                result = utf8.isHexDigit(char);
            }
        }

        return result;
    }

    pub usingnamespace MatcherModifiers;
};

pub const CharMatcher = struct {
    char: u8,

    pub fn match(self: *const CharMatcher, reader: *Reader) bool {
        var result = true;

        if (reader.next()) |char| {
            result = char == utf8.fromASCII(self.char);
        } else {
            result = false;
        }

        return result;
    }

    pub usingnamespace MatcherModifiers;
};

pub const CodePointMatcher = struct {
    codepoint: CodePoint,

    pub fn match(self: *const CodePointMatcher, reader: *Reader) bool {
        var result = true;

        if (reader.next()) |char| {
            result = char == self.codepoint;
        } else {
            result = false;
        }

        return result;
    }

    pub usingnamespace MatcherModifiers;
};

pub const StringMatcher = struct {
    string: []const u8,

    pub fn match(self: *const StringMatcher, reader: *Reader) bool {
        var result = true;

        var i: usize = 0;
        while (i < self.string.len) : (i += 1) {
            if (reader.next()) |char| {
                if (self.string[i] != char) {
                    result = false;
                }
            } else {
                result = false;
            }
        }

        return result;
    }

    pub usingnamespace MatcherModifiers;
};

pub const OneOfCharsMatcher = struct {
    string: []const u8,

    pub fn match(self: *const OneOfCharsMatcher, reader: *Reader) bool {
        var result = false;

        if (reader.next()) |char| {
            for (self.string) |expected_char| {
                if (char == expected_char) {
                    // If we found a match, we can stop the search
                    result = true;
                    break;
                }
            }
        }

        return result;
    }

    pub usingnamespace MatcherModifiers;
};

pub fn OneOfMatcher(comptime AlternativeMatchers: type) type {
    return struct {
        alternative_matchers: AlternativeMatchers,

        pub fn match(self: *const @This(), reader: *Reader) bool {
            inline for (std.meta.fields(AlternativeMatchers)) |field| {
                var child_matcher = &@field(self.alternative_matchers, field.name);

                var child_reader = reader.*;

                if (child_matcher.match(&child_reader)) {
                    // If we found a match, we can stop the search
                    // TODO Implement multiple search strategies, such as longest match or first match
                    reader.* = child_reader;
                    return true;
                }
            }

            // If no alternative was a match, then return no match
            return false;
        }

        pub usingnamespace MatcherModifiers;
    };
}

/// Matches strings of the following pattern:
///    r"Hello"
///    r##"Hello "# Goodbye "##
pub const RawQuotedStringMatcher = struct {
    pub fn match(self: *const RawQuotedStringMatcher, reader: *Reader) bool {
        _ = self;

        var char = reader.next() orelse return false;

        if (char != utf8.fromASCII('r')) {
            return false;
        }

        var hashes_count: usize = 0;

        char = reader.next() orelse return false;

        while (char == utf8.fromASCII('#')) {
            hashes_count += 1;

            char = reader.next() orelse return false;
        }

        if (char != utf8.fromASCII('"')) {
            return false;
        }

        var ending: bool = false;
        var hashes_end_count: usize = 0;

        while (true) {
            char = reader.next() orelse return false;

            if (ending) {
                if (char == utf8.fromASCII('#')) {
                    hashes_end_count += 1;
                } else {
                    hashes_end_count = 0;
                    ending = false;
                }
            } else {
                if (char == utf8.fromASCII('"')) {
                    ending = true;
                }
            }

            if (ending and hashes_end_count >= hashes_count) {
                break;
            }
        }

        return true;
    }
};

pub fn SequenceMatcher(comptime SegmentMatchers: type) type {
    return struct {
        segment_matchers: SegmentMatchers,

        pub fn match(self: *const @This(), reader: *Reader) bool {
            inline for (std.meta.fields(SegmentMatchers)) |field| {
                var child_matcher = &@field(self.segment_matchers, field.name);

                if (!child_matcher.match(reader)) {
                    return false;
                }
            }

            return true;
        }

        pub usingnamespace MatcherModifiers;
    };
}

pub const MatcherModifiers = struct {
    pub fn negate(self: anytype) NegateMatcher(@TypeOf(self)) {
        return NegateMatcher(@TypeOf(self)){ .child_matcher = self };
    }

    pub fn optional(self: anytype) OptionalMatcher(@TypeOf(self)) {
        return OptionalMatcher(@TypeOf(self)){ .child_matcher = self };
    }

    pub fn lookahead(self: anytype) LookaheadMatcher(@TypeOf(self)) {
        return LookaheadMatcher{ .child_matcher = self };
    }

    pub fn repeat(self: anytype, options: RepeatMatcherOptions) RepeatMatcher(@TypeOf(self)) {
        return RepeatMatcher(@TypeOf(self)){
            .child_matcher = self,
            .options = options,
        };
    }

    pub fn atLeastOnce(self: anytype) RepeatMatcher(@TypeOf(self)) {
        return self.repeat(.{ .min = 1 });
    }

    pub fn except(self: anytype, excluded: anytype, mode: ExceptMatcherMode) ExceptMatcher(@TypeOf(self), @TypeOf(excluded)) {
        return ExceptMatcher(@TypeOf(self), @TypeOf(excluded)){
            .main_matcher = self,
            .excluded_matchers = excluded,
            .mode = mode,
        };
    }
};

pub const ExceptMatcherMode = enum {
    start,
    anywhere,
    end,
    full,
};

pub fn ExceptMatcher(
    comptime MainMatcher: type,
    comptime ExcludedMatchers: type,
) type {
    return struct {
        main_matcher: MainMatcher,
        excluded_matchers: ExcludedMatchers,
        mode: ExceptMatcherMode,

        pub fn match(self: *const @This(), reader: *Reader) bool {
            var initial_reader = reader.*;

            if (!self.main_matcher.match(reader)) {
                return false;
            }

            var success_match = true;

            // If the mode is start
            if (self.mode == .start or self.mode == .full) {
                inline for (std.meta.fields(ExcludedMatchers)) |field| {
                    var child_matcher = &@field(self.excluded_matchers, field.name);

                    var child_reader = initial_reader;

                    // If one of the excluded matchers was a match, we might have
                    // to report this this whole matcher as failed
                    if (child_matcher.match(&child_reader)) {
                        // But if the mode is .full, then the offset must have matched the whole offset
                        if (self.mode != .full or
                            child_reader.location.offset >= reader.location.offset)
                        {
                            success_match = false;
                            break;
                        }
                    }
                }
            } else if (self.mode == .anywhere or self.mode == .end) {
                inline for (std.meta.fields(ExcludedMatchers)) |field| {
                    var child_matcher = &@field(self.excluded_matchers, field.name);

                    var chars_to_skip: usize = 0;

                    while (true) {
                        var child_reader = initial_reader;

                        child_reader.skip(chars_to_skip);

                        chars_to_skip += 1;

                        if (child_reader.location.offset >= initial_reader.location.offset) {
                            break;
                        }

                        // If one of the excluded matchers was a match, we might have
                        // to report this this whole matcher as failed
                        if (child_matcher.match(&child_reader)) {
                            // But if the mode is .full, then the offset must have matched the whole offset
                            if (self.mode != .end or
                                child_reader.location.offset >= reader.location.offset)
                            {
                                success_match = false;
                                break;
                            }
                        }
                    }

                    // If we already found one of the excluded matches, no need
                    // to continue searching
                    if (!success_match) {
                        break;
                    }
                }
            }

            return success_match;
        }
    };
}

pub fn NegateMatcher(comptime ChildMatcher: type) type {
    return struct {
        child_matcher: ChildMatcher,

        pub fn match(self: *const @This(), reader: *Reader) bool {
            var negated_reader = reader.*;

            // If the child succeeds, the negate should fail
            if (self.child_matcher.match(&negated_reader)) {
                return false;
            }

            // If we validate that the child_matcher does not match, we move our
            // cursor one position
            // _ = reader.next();

            return true;
        }

        pub usingnamespace MatcherModifiers;
    };
}

pub fn LookaheadMatcher(comptime ChildMatcher: type) type {
    return struct {
        child_matcher: ChildMatcher,

        pub fn match(self: *const @This(), reader: *Reader) bool {
            var negated_reader = reader.*;

            return self.child_matcher.match(&negated_reader);
        }

        pub usingnamespace MatcherModifiers;
    };
}

pub fn OptionalMatcher(comptime ChildMatcher: type) type {
    return struct {
        child_matcher: ChildMatcher,

        pub fn match(self: *const @This(), reader: *Reader) bool {
            // Copy (fork) the reader so if the child matcher fails,
            // we can keep the previous reader position
            var optional_reader = reader.*;

            // If the child matcher fails, just return without changing the original reader
            if (!self.child_matcher.match(&optional_reader)) {
                return true;
            }

            // If the child matcher succeeds, replace the original reader with the cloned one
            reader.* = optional_reader;

            return true;
        }

        pub usingnamespace MatcherModifiers;
    };
}

pub const RepeatMatcherOptions = struct {
    min: ?usize = null,
    max: ?usize = null,
};

pub fn RepeatMatcher(comptime ChildMatcher: type) type {
    return struct {
        child_matcher: ChildMatcher,
        options: RepeatMatcherOptions = .{},

        pub fn match(self: *const @This(), reader: *Reader) bool {
            // We need to count how many matches we have found, to know if the
            // overall match of the RepeatMatcher was successful or not,
            // based on the values provided in the options
            var match_count: usize = 0;

            // Should never happen, but if the number of max_matches is zero,
            // we must handle it seperately
            if (self.options.max) |max_matches| {
                // First we need to check if the number of minimum matches is also set,
                // and is greater than it, in which case we can report a failure immediately
                if (self.options.min) |min_matches| {
                    if (min_matches > max_matches) {
                        return false;
                    }
                }

                // On the other hand, if the number of max_matches allowed is zero,
                // we always return success. Note that we don't need to test:
                // even if the test was successful, meaning we had one match,
                // this RepeatMatcher works in a best effor basis: it tries to
                // match as many times as possible within the range configured in
                // the options. If there are not enough matches it fails, but if
                // there are more than enough, it "consumes" only those it needs
                // and stops there, returning success. If the max is zero,
                // success is always garanteed in that case.
                if (max_matches == 0) {
                    return true;
                }
            }

            // Copy (fork) the reader so if the child matcher fails,
            // we can keep the previous reader position
            var repeat_reader = reader.*;

            // Used to prevent infinite loops: if you call child_matcher once
            // and it claims success but does not advance the reader in any way,
            // then we can consider that it failed. Since it would be trying to match
            // the same position all the time, it would never break the loop or
            // advance the reader, so we just cut it short
            var last_offset = reader.location.offset;

            while (self.child_matcher.match(&repeat_reader) and
                repeat_reader.location.offset > last_offset)
            {
                match_count += 1;

                last_offset = repeat_reader.location.offset;

                // If this match was successful, and we have already matched the minimum
                // number required, we can "commit" our reader location since we are sure
                // we will succeed overall
                if (self.options.min == null or self.options.min.? <= match_count) {
                    reader.* = repeat_reader;
                }

                // RepeatMatcher greedly matches as many times as possible
                // When options.max is not null, we stop once we hit the
                // configured number of max matches, and don't test any further,
                // even if there could be more positive matches ahead
                if (self.options.max) |max_matches| {
                    if (match_count >= max_matches) {
                        break;
                    }
                }
            }

            // Here we have matches as many times as possible.
            // Now we need to check if there is a configured amount of minimum
            // matches needed for this RepeatMatcher to be configured successful,
            // and in that case, we can claim success. Otherwise, we must return false
            if (self.options.min) |min_matches| {
                if (match_count < min_matches) {
                    return false;
                }
            }

            return true;
        }

        pub usingnamespace MatcherModifiers;
    };
}

fn expectReader(reader: Reader, offset: usize, line: usize, column: usize) !void {
    try std.testing.expectEqual(offset, reader.location.offset);
    try std.testing.expectEqual(line, reader.location.line);
    try std.testing.expectEqual(column, reader.location.column);
}

test "Match characters and strings" {
    var reader = try Reader.init("node {}");
    try std.testing.expectEqual(@as(Reader.State, .bof), reader.state);

    try std.testing.expectEqual(true, Matcher.char('n').match(&reader));
    try expectReader(reader, 1, 0, 1);

    try std.testing.expectEqual(true, Matcher.string("ode").match(&reader));
    try expectReader(reader, 4, 0, 4);
}

test "Match alternatives" {
    var reader = try Reader.init("node {}");

    var matcher1 = Matcher.oneOf(.{
        Matcher.char('a'),
        Matcher.string("nade"),
        Matcher.string("nod"), // <-- should match this
        Matcher.char('n'),
    });
    try std.testing.expectEqual(true, matcher1.match(&reader));
    try expectReader(reader, 3, 0, 3);

    reader.reset();

    // Empty sequence should never match
    var matcher2 = Matcher.oneOf(.{});

    try std.testing.expectEqual(false, matcher2.match(&reader));
}

test "Match sequences" {
    var reader = try Reader.init("node {}");

    var matcher1 = Matcher.sequence(.{
        Matcher.oneOf(.{
            Matcher.char('a'),
            Matcher.string("nade"),
            Matcher.string("nod"), // <-- should match this
            Matcher.char('n'),
        }),
        Matcher.string("e {}"),
    });

    try std.testing.expectEqual(true, matcher1.match(&reader));
    try expectReader(reader, 7, 0, 7);

    reader.reset();

    // Empty sequence should always match
    var matcher2 = Matcher.sequence(.{});

    try std.testing.expectEqual(true, matcher2.match(&reader));
    try expectReader(reader, 0, 0, 0);
}

test "Match repeat" {
    var reader = try Reader.init("AAAA");

    var matcher1 = Matcher.string("AA").repeat(.{});
    try std.testing.expectEqual(true, matcher1.match(&reader));
    try expectReader(reader, 4, 0, 4);

    reader.reset();

    var matcher2 = Matcher.string("A").repeat(.{ .max = 2 });
    try std.testing.expectEqual(true, matcher2.match(&reader));
    try expectReader(reader, 2, 0, 2);

    reader.reset();

    // Repeat with no minimum succeeds even if nothing matches
    var matcher3 = Matcher.string("AB").repeat(.{ .max = 2 });
    try std.testing.expectEqual(true, matcher3.match(&reader));
    try expectReader(reader, 0, 0, 0);

    // Repeat with a minimum fails if nothing matches
    var matcher4 = Matcher.string("AB").repeat(.{ .min = 1, .max = 2 });
    try std.testing.expectEqual(false, matcher4.match(&reader));
}

test "Match optional" {
    var reader = try Reader.init("node {}");

    var matcher1 = Matcher.sequence(.{
        Matcher.string("$no").optional(),
        Matcher.string("de"),
    });
    try std.testing.expectEqual(false, matcher1.match(&reader));

    reader.reset();

    var matcher2 = Matcher.sequence(.{
        Matcher.string("no").optional(),
        Matcher.string("de"),
    });
    try std.testing.expectEqual(true, matcher2.match(&reader));
    try expectReader(reader, 4, 0, 4);
}

test "Match negate" {
    var matcher1 = Matcher.sequence(.{
        Matcher.string("$").negate(),
        Matcher.string("no"),
        Matcher.string("de"),
    });

    var reader = try Reader.init("$node {}");
    try std.testing.expectEqual(false, matcher1.match(&reader));

    reader = try Reader.init("node {}");
    try std.testing.expectEqual(true, matcher1.match(&reader));
    try expectReader(reader, 4, 0, 4);
}

test "Match whitespace" {
    var matcher = Matcher.whitespace().repeat(.{ .min = 1 });

    var reader = try Reader.init(" \t  ");
    try std.testing.expectEqual(true, matcher.match(&reader));
    try expectReader(reader, 4, 0, 4);

    reader = try Reader.init(" \t node {}");
    try std.testing.expectEqual(true, matcher.match(&reader));
    try expectReader(reader, 3, 0, 3);
}

test "Match newline" {
    var matcher = Matcher.newline().repeat(.{ .min = 1 });

    var reader = try Reader.init("\n\r\n\n");
    try std.testing.expectEqual(true, matcher.match(&reader));
    try expectReader(reader, 4, 3, 0);

    reader = try Reader.init("\n\r\nnode {}");
    try std.testing.expectEqual(true, matcher.match(&reader));
    try expectReader(reader, 3, 2, 0);
}

test "Match oneOfChars" {
    var matcher = Matcher.oneOfChars("\"\\/bn");

    var reader = try Reader.init("\\nb\"/a");
    try std.testing.expectEqual(true, matcher.match(&reader));
    try expectReader(reader, 1, 0, 1);

    try std.testing.expectEqual(true, matcher.match(&reader));
    try expectReader(reader, 2, 0, 2);

    try std.testing.expectEqual(true, matcher.match(&reader));
    try expectReader(reader, 3, 0, 3);

    try std.testing.expectEqual(true, matcher.match(&reader));
    try expectReader(reader, 4, 0, 4);

    try std.testing.expectEqual(true, matcher.match(&reader));
    try expectReader(reader, 5, 0, 5);

    try std.testing.expectEqual(false, matcher.match(&reader));
    try expectReader(reader, 6, 0, 6);
}

test "Match except" {
    var matcher = Matcher.sequence(.{
        Matcher.oneOfChars("123456789").repeat(.{}),
        Matcher.eof(),
    }).except(.{ Matcher.string("911"), Matcher.string("112") }, .full);

    var reader = try Reader.init("122abc");
    try std.testing.expectEqual(false, matcher.match(&reader));
    try expectReader(reader, 4, 0, 4);

    reader = try Reader.init("122");
    try std.testing.expectEqual(true, matcher.match(&reader));
    try expectReader(reader, 3, 0, 3);

    reader = try Reader.init("911");
    try std.testing.expectEqual(false, matcher.match(&reader));
    try expectReader(reader, 3, 0, 3);

    reader = try Reader.init("9112");
    try std.testing.expectEqual(true, matcher.match(&reader));
    try expectReader(reader, 4, 0, 4);

    reader = try Reader.init("2911");
    try std.testing.expectEqual(true, matcher.match(&reader));
    try expectReader(reader, 4, 0, 4);
}

test "Match eof" {
    var matcher = Matcher.eof();

    var reader = try Reader.init("122abc");
    try std.testing.expectEqual(false, matcher.match(&reader));
    try expectReader(reader, 1, 0, 1);

    reader = try Reader.init("");
    try std.testing.expectEqual(true, matcher.match(&reader));
    try expectReader(reader, 0, 0, 0);
}

test "Match rawQuotedString" {
    var matcher = Matcher.rawQuotedString();

    var reader = try Reader.init("r\"foobar\" true");
    try std.testing.expectEqual(true, matcher.match(&reader));
    try expectReader(reader, 9, 0, 9);

    reader = try Reader.init("r##\"foobar\"## true");
    try std.testing.expectEqual(true, matcher.match(&reader));
    try expectReader(reader, 13, 0, 13);

    reader = try Reader.init("r##\"foobar\"# true");
    try std.testing.expectEqual(false, matcher.match(&reader));
    try expectReader(reader, 17, 0, 17);
}
