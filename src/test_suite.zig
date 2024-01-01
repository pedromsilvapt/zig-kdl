const std = @import("std");
const helpers = @import("./test_suite_helpers.zig");


test "TestSuite HappyPath: all_escapes." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/all_escapes.kdl"), @embedFile("./test_suite/expected_kdl/all_escapes.kdl"));
}

test "TestSuite HappyPath: all_node_fields." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/all_node_fields.kdl"), @embedFile("./test_suite/expected_kdl/all_node_fields.kdl"));
}

test "TestSuite HappyPath: arg_and_prop_same_name." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/arg_and_prop_same_name.kdl"), @embedFile("./test_suite/expected_kdl/arg_and_prop_same_name.kdl"));
}

test "TestSuite HappyPath: arg_false_type." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/arg_false_type.kdl"), @embedFile("./test_suite/expected_kdl/arg_false_type.kdl"));
}

test "TestSuite HappyPath: arg_float_type." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/arg_float_type.kdl"), @embedFile("./test_suite/expected_kdl/arg_float_type.kdl"));
}

test "TestSuite HappyPath: arg_hex_type." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/arg_hex_type.kdl"), @embedFile("./test_suite/expected_kdl/arg_hex_type.kdl"));
}

test "TestSuite HappyPath: arg_null_type." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/arg_null_type.kdl"), @embedFile("./test_suite/expected_kdl/arg_null_type.kdl"));
}

test "TestSuite HappyPath: arg_raw_string_type." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/arg_raw_string_type.kdl"), @embedFile("./test_suite/expected_kdl/arg_raw_string_type.kdl"));
}

test "TestSuite HappyPath: arg_string_type." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/arg_string_type.kdl"), @embedFile("./test_suite/expected_kdl/arg_string_type.kdl"));
}

test "TestSuite HappyPath: arg_true_type." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/arg_true_type.kdl"), @embedFile("./test_suite/expected_kdl/arg_true_type.kdl"));
}

test "TestSuite HappyPath: arg_type." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/arg_type.kdl"), @embedFile("./test_suite/expected_kdl/arg_type.kdl"));
}

test "TestSuite HappyPath: arg_zero_type." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/arg_zero_type.kdl"), @embedFile("./test_suite/expected_kdl/arg_zero_type.kdl"));
}

test "TestSuite HappyPath: asterisk_in_block_comment." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/asterisk_in_block_comment.kdl"), @embedFile("./test_suite/expected_kdl/asterisk_in_block_comment.kdl"));
}

test "TestSuite FailPath: backslash_in_bare_id." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteFailTestCase(allocator, @embedFile("./test_suite/input/backslash_in_bare_id.kdl"));
}

test "TestSuite FailPath: bare_arg." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteFailTestCase(allocator, @embedFile("./test_suite/input/bare_arg.kdl"));
}

test "TestSuite HappyPath: bare_emoji." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/bare_emoji.kdl"), @embedFile("./test_suite/expected_kdl/bare_emoji.kdl"));
}

test "TestSuite HappyPath: binary." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/binary.kdl"), @embedFile("./test_suite/expected_kdl/binary.kdl"));
}

test "TestSuite HappyPath: binary_trailing_underscore." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/binary_trailing_underscore.kdl"), @embedFile("./test_suite/expected_kdl/binary_trailing_underscore.kdl"));
}

test "TestSuite HappyPath: binary_underscore." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/binary_underscore.kdl"), @embedFile("./test_suite/expected_kdl/binary_underscore.kdl"));
}

test "TestSuite HappyPath: blank_arg_type." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/blank_arg_type.kdl"), @embedFile("./test_suite/expected_kdl/blank_arg_type.kdl"));
}

test "TestSuite HappyPath: blank_node_type." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/blank_node_type.kdl"), @embedFile("./test_suite/expected_kdl/blank_node_type.kdl"));
}

test "TestSuite HappyPath: blank_prop_type." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/blank_prop_type.kdl"), @embedFile("./test_suite/expected_kdl/blank_prop_type.kdl"));
}

test "TestSuite HappyPath: block_comment." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/block_comment.kdl"), @embedFile("./test_suite/expected_kdl/block_comment.kdl"));
}

test "TestSuite HappyPath: block_comment_after_node." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/block_comment_after_node.kdl"), @embedFile("./test_suite/expected_kdl/block_comment_after_node.kdl"));
}

test "TestSuite HappyPath: block_comment_before_node." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/block_comment_before_node.kdl"), @embedFile("./test_suite/expected_kdl/block_comment_before_node.kdl"));
}

test "TestSuite HappyPath: block_comment_before_node_no_space." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/block_comment_before_node_no_space.kdl"), @embedFile("./test_suite/expected_kdl/block_comment_before_node_no_space.kdl"));
}

test "TestSuite HappyPath: block_comment_newline." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/block_comment_newline.kdl"), @embedFile("./test_suite/expected_kdl/block_comment_newline.kdl"));
}

test "TestSuite HappyPath: boolean_arg." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/boolean_arg.kdl"), @embedFile("./test_suite/expected_kdl/boolean_arg.kdl"));
}

test "TestSuite HappyPath: boolean_prop." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/boolean_prop.kdl"), @embedFile("./test_suite/expected_kdl/boolean_prop.kdl"));
}

test "TestSuite FailPath: brackets_in_bare_id." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteFailTestCase(allocator, @embedFile("./test_suite/input/brackets_in_bare_id.kdl"));
}

test "TestSuite FailPath: chevrons_in_bare_id." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteFailTestCase(allocator, @embedFile("./test_suite/input/chevrons_in_bare_id.kdl"));
}

test "TestSuite FailPath: comma_in_bare_id." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteFailTestCase(allocator, @embedFile("./test_suite/input/comma_in_bare_id.kdl"));
}

test "TestSuite HappyPath: commented_arg." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/commented_arg.kdl"), @embedFile("./test_suite/expected_kdl/commented_arg.kdl"));
}

test "TestSuite HappyPath: commented_child." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/commented_child.kdl"), @embedFile("./test_suite/expected_kdl/commented_child.kdl"));
}

test "TestSuite HappyPath: commented_line." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/commented_line.kdl"), @embedFile("./test_suite/expected_kdl/commented_line.kdl"));
}

test "TestSuite HappyPath: commented_node." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/commented_node.kdl"), @embedFile("./test_suite/expected_kdl/commented_node.kdl"));
}

test "TestSuite HappyPath: commented_prop." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/commented_prop.kdl"), @embedFile("./test_suite/expected_kdl/commented_prop.kdl"));
}

test "TestSuite FailPath: comment_after_arg_type." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteFailTestCase(allocator, @embedFile("./test_suite/input/comment_after_arg_type.kdl"));
}

test "TestSuite FailPath: comment_after_node_type." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteFailTestCase(allocator, @embedFile("./test_suite/input/comment_after_node_type.kdl"));
}

test "TestSuite FailPath: comment_after_prop_type." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteFailTestCase(allocator, @embedFile("./test_suite/input/comment_after_prop_type.kdl"));
}

test "TestSuite FailPath: comment_in_arg_type." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteFailTestCase(allocator, @embedFile("./test_suite/input/comment_in_arg_type.kdl"));
}

test "TestSuite FailPath: comment_in_node_type." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteFailTestCase(allocator, @embedFile("./test_suite/input/comment_in_node_type.kdl"));
}

test "TestSuite FailPath: comment_in_prop_type." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteFailTestCase(allocator, @embedFile("./test_suite/input/comment_in_prop_type.kdl"));
}

test "TestSuite HappyPath: crlf_between_nodes." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/crlf_between_nodes.kdl"), @embedFile("./test_suite/expected_kdl/crlf_between_nodes.kdl"));
}

test "TestSuite FailPath: dash_dash." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteFailTestCase(allocator, @embedFile("./test_suite/input/dash_dash.kdl"));
}

test "TestSuite FailPath: dot_but_no_fraction." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteFailTestCase(allocator, @embedFile("./test_suite/input/dot_but_no_fraction.kdl"));
}

test "TestSuite FailPath: dot_but_no_fraction_before_exponent." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteFailTestCase(allocator, @embedFile("./test_suite/input/dot_but_no_fraction_before_exponent.kdl"));
}

test "TestSuite FailPath: dot_in_exponent." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteFailTestCase(allocator, @embedFile("./test_suite/input/dot_in_exponent.kdl"));
}

test "TestSuite FailPath: dot_zero." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteFailTestCase(allocator, @embedFile("./test_suite/input/dot_zero.kdl"));
}

test "TestSuite HappyPath: emoji." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/emoji.kdl"), @embedFile("./test_suite/expected_kdl/emoji.kdl"));
}

test "TestSuite HappyPath: empty." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/empty.kdl"), @embedFile("./test_suite/expected_kdl/empty.kdl"));
}

test "TestSuite FailPath: empty_arg_type." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteFailTestCase(allocator, @embedFile("./test_suite/input/empty_arg_type.kdl"));
}

test "TestSuite HappyPath: empty_child." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/empty_child.kdl"), @embedFile("./test_suite/expected_kdl/empty_child.kdl"));
}

test "TestSuite HappyPath: empty_child_different_lines." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/empty_child_different_lines.kdl"), @embedFile("./test_suite/expected_kdl/empty_child_different_lines.kdl"));
}

test "TestSuite HappyPath: empty_child_same_line." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/empty_child_same_line.kdl"), @embedFile("./test_suite/expected_kdl/empty_child_same_line.kdl"));
}

test "TestSuite HappyPath: empty_child_whitespace." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/empty_child_whitespace.kdl"), @embedFile("./test_suite/expected_kdl/empty_child_whitespace.kdl"));
}

test "TestSuite FailPath: empty_node_type." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteFailTestCase(allocator, @embedFile("./test_suite/input/empty_node_type.kdl"));
}

test "TestSuite FailPath: empty_prop_type." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteFailTestCase(allocator, @embedFile("./test_suite/input/empty_prop_type.kdl"));
}

test "TestSuite HappyPath: empty_quoted_node_id." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/empty_quoted_node_id.kdl"), @embedFile("./test_suite/expected_kdl/empty_quoted_node_id.kdl"));
}

test "TestSuite HappyPath: empty_quoted_prop_key." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/empty_quoted_prop_key.kdl"), @embedFile("./test_suite/expected_kdl/empty_quoted_prop_key.kdl"));
}

test "TestSuite HappyPath: empty_string_arg." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/empty_string_arg.kdl"), @embedFile("./test_suite/expected_kdl/empty_string_arg.kdl"));
}

test "TestSuite HappyPath: escline." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/escline.kdl"), @embedFile("./test_suite/expected_kdl/escline.kdl"));
}

test "TestSuite FailPath: escline_comment_node." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteFailTestCase(allocator, @embedFile("./test_suite/input/escline_comment_node.kdl"));
}

test "TestSuite HappyPath: escline_line_comment." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/escline_line_comment.kdl"), @embedFile("./test_suite/expected_kdl/escline_line_comment.kdl"));
}

test "TestSuite HappyPath: escline_node." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/escline_node.kdl"), @embedFile("./test_suite/expected_kdl/escline_node.kdl"));
}

test "TestSuite HappyPath: esc_newline_in_string." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/esc_newline_in_string.kdl"), @embedFile("./test_suite/expected_kdl/esc_newline_in_string.kdl"));
}

test "TestSuite HappyPath: esc_unicode_in_string." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/esc_unicode_in_string.kdl"), @embedFile("./test_suite/expected_kdl/esc_unicode_in_string.kdl"));
}

test "TestSuite HappyPath: false_prefix_in_bare_id." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/false_prefix_in_bare_id.kdl"), @embedFile("./test_suite/expected_kdl/false_prefix_in_bare_id.kdl"));
}

test "TestSuite HappyPath: false_prefix_in_prop_key." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/false_prefix_in_prop_key.kdl"), @embedFile("./test_suite/expected_kdl/false_prefix_in_prop_key.kdl"));
}

test "TestSuite FailPath: false_prop_key." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteFailTestCase(allocator, @embedFile("./test_suite/input/false_prop_key.kdl"));
}

test "TestSuite HappyPath: hex." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/hex.kdl"), @embedFile("./test_suite/expected_kdl/hex.kdl"));
}

test "TestSuite HappyPath: hex_int." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/hex_int.kdl"), @embedFile("./test_suite/expected_kdl/hex_int.kdl"));
}

test "TestSuite HappyPath: hex_int_underscores." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/hex_int_underscores.kdl"), @embedFile("./test_suite/expected_kdl/hex_int_underscores.kdl"));
}

test "TestSuite HappyPath: hex_leading_zero." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/hex_leading_zero.kdl"), @embedFile("./test_suite/expected_kdl/hex_leading_zero.kdl"));
}

test "TestSuite FailPath: illegal_char_in_binary." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteFailTestCase(allocator, @embedFile("./test_suite/input/illegal_char_in_binary.kdl"));
}

test "TestSuite FailPath: illegal_char_in_hex." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteFailTestCase(allocator, @embedFile("./test_suite/input/illegal_char_in_hex.kdl"));
}

test "TestSuite FailPath: illegal_char_in_octal." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteFailTestCase(allocator, @embedFile("./test_suite/input/illegal_char_in_octal.kdl"));
}

test "TestSuite HappyPath: int_multiple_underscore." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/int_multiple_underscore.kdl"), @embedFile("./test_suite/expected_kdl/int_multiple_underscore.kdl"));
}

test "TestSuite HappyPath: just_block_comment." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/just_block_comment.kdl"), @embedFile("./test_suite/expected_kdl/just_block_comment.kdl"));
}

test "TestSuite HappyPath: just_child." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/just_child.kdl"), @embedFile("./test_suite/expected_kdl/just_child.kdl"));
}

test "TestSuite HappyPath: just_newline." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/just_newline.kdl"), @embedFile("./test_suite/expected_kdl/just_newline.kdl"));
}

test "TestSuite HappyPath: just_node_id." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/just_node_id.kdl"), @embedFile("./test_suite/expected_kdl/just_node_id.kdl"));
}

test "TestSuite HappyPath: just_space." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/just_space.kdl"), @embedFile("./test_suite/expected_kdl/just_space.kdl"));
}

test "TestSuite FailPath: just_space_in_arg_type." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteFailTestCase(allocator, @embedFile("./test_suite/input/just_space_in_arg_type.kdl"));
}

test "TestSuite FailPath: just_space_in_node_type." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteFailTestCase(allocator, @embedFile("./test_suite/input/just_space_in_node_type.kdl"));
}

test "TestSuite FailPath: just_space_in_prop_type." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteFailTestCase(allocator, @embedFile("./test_suite/input/just_space_in_prop_type.kdl"));
}

test "TestSuite FailPath: just_type_no_arg." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteFailTestCase(allocator, @embedFile("./test_suite/input/just_type_no_arg.kdl"));
}

test "TestSuite FailPath: just_type_no_node_id." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteFailTestCase(allocator, @embedFile("./test_suite/input/just_type_no_node_id.kdl"));
}

test "TestSuite FailPath: just_type_no_prop." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteFailTestCase(allocator, @embedFile("./test_suite/input/just_type_no_prop.kdl"));
}

test "TestSuite HappyPath: leading_newline." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/leading_newline.kdl"), @embedFile("./test_suite/expected_kdl/leading_newline.kdl"));
}

test "TestSuite HappyPath: leading_zero_binary." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/leading_zero_binary.kdl"), @embedFile("./test_suite/expected_kdl/leading_zero_binary.kdl"));
}

test "TestSuite HappyPath: leading_zero_int." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/leading_zero_int.kdl"), @embedFile("./test_suite/expected_kdl/leading_zero_int.kdl"));
}

test "TestSuite HappyPath: leading_zero_oct." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/leading_zero_oct.kdl"), @embedFile("./test_suite/expected_kdl/leading_zero_oct.kdl"));
}

test "TestSuite HappyPath: multiline_comment." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/multiline_comment.kdl"), @embedFile("./test_suite/expected_kdl/multiline_comment.kdl"));
}

test "TestSuite HappyPath: multiline_nodes." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/multiline_nodes.kdl"), @embedFile("./test_suite/expected_kdl/multiline_nodes.kdl"));
}

test "TestSuite HappyPath: multiline_string." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/multiline_string.kdl"), @embedFile("./test_suite/expected_kdl/multiline_string.kdl"));
}

test "TestSuite FailPath: multiple_dots_in_float." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteFailTestCase(allocator, @embedFile("./test_suite/input/multiple_dots_in_float.kdl"));
}

test "TestSuite FailPath: multiple_dots_in_float_before_exponent." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteFailTestCase(allocator, @embedFile("./test_suite/input/multiple_dots_in_float_before_exponent.kdl"));
}

test "TestSuite FailPath: multiple_es_in_float." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteFailTestCase(allocator, @embedFile("./test_suite/input/multiple_es_in_float.kdl"));
}

test "TestSuite FailPath: multiple_x_in_hex." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteFailTestCase(allocator, @embedFile("./test_suite/input/multiple_x_in_hex.kdl"));
}

test "TestSuite HappyPath: negative_exponent." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/negative_exponent.kdl"), @embedFile("./test_suite/expected_kdl/negative_exponent.kdl"));
}

test "TestSuite HappyPath: negative_float." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/negative_float.kdl"), @embedFile("./test_suite/expected_kdl/negative_float.kdl"));
}

test "TestSuite HappyPath: negative_int." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/negative_int.kdl"), @embedFile("./test_suite/expected_kdl/negative_int.kdl"));
}

test "TestSuite HappyPath: nested_block_comment." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/nested_block_comment.kdl"), @embedFile("./test_suite/expected_kdl/nested_block_comment.kdl"));
}

test "TestSuite HappyPath: nested_children." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/nested_children.kdl"), @embedFile("./test_suite/expected_kdl/nested_children.kdl"));
}

test "TestSuite HappyPath: nested_comments." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/nested_comments.kdl"), @embedFile("./test_suite/expected_kdl/nested_comments.kdl"));
}

test "TestSuite HappyPath: nested_multiline_block_comment." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/nested_multiline_block_comment.kdl"), @embedFile("./test_suite/expected_kdl/nested_multiline_block_comment.kdl"));
}

test "TestSuite HappyPath: newlines_in_block_comment." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/newlines_in_block_comment.kdl"), @embedFile("./test_suite/expected_kdl/newlines_in_block_comment.kdl"));
}

test "TestSuite HappyPath: newline_between_nodes." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/newline_between_nodes.kdl"), @embedFile("./test_suite/expected_kdl/newline_between_nodes.kdl"));
}

test "TestSuite HappyPath: node_false." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/node_false.kdl"), @embedFile("./test_suite/expected_kdl/node_false.kdl"));
}

test "TestSuite HappyPath: node_true." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/node_true.kdl"), @embedFile("./test_suite/expected_kdl/node_true.kdl"));
}

test "TestSuite HappyPath: node_type." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/node_type.kdl"), @embedFile("./test_suite/expected_kdl/node_type.kdl"));
}

test "TestSuite HappyPath: no_decimal_exponent." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/no_decimal_exponent.kdl"), @embedFile("./test_suite/expected_kdl/no_decimal_exponent.kdl"));
}

test "TestSuite FailPath: no_digits_in_hex." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteFailTestCase(allocator, @embedFile("./test_suite/input/no_digits_in_hex.kdl"));
}

test "TestSuite HappyPath: null_arg." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/null_arg.kdl"), @embedFile("./test_suite/expected_kdl/null_arg.kdl"));
}

test "TestSuite HappyPath: null_prefix_in_bare_id." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/null_prefix_in_bare_id.kdl"), @embedFile("./test_suite/expected_kdl/null_prefix_in_bare_id.kdl"));
}

test "TestSuite HappyPath: null_prefix_in_prop_key." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/null_prefix_in_prop_key.kdl"), @embedFile("./test_suite/expected_kdl/null_prefix_in_prop_key.kdl"));
}

test "TestSuite HappyPath: null_prop." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/null_prop.kdl"), @embedFile("./test_suite/expected_kdl/null_prop.kdl"));
}

test "TestSuite FailPath: null_prop_key." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteFailTestCase(allocator, @embedFile("./test_suite/input/null_prop_key.kdl"));
}

test "TestSuite HappyPath: numeric_arg." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/numeric_arg.kdl"), @embedFile("./test_suite/expected_kdl/numeric_arg.kdl"));
}

test "TestSuite HappyPath: numeric_prop." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/numeric_prop.kdl"), @embedFile("./test_suite/expected_kdl/numeric_prop.kdl"));
}

test "TestSuite HappyPath: octal." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/octal.kdl"), @embedFile("./test_suite/expected_kdl/octal.kdl"));
}

test "TestSuite HappyPath: only_cr." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/only_cr.kdl"), @embedFile("./test_suite/expected_kdl/only_cr.kdl"));
}

test "TestSuite HappyPath: only_line_comment." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/only_line_comment.kdl"), @embedFile("./test_suite/expected_kdl/only_line_comment.kdl"));
}

test "TestSuite HappyPath: only_line_comment_crlf." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/only_line_comment_crlf.kdl"), @embedFile("./test_suite/expected_kdl/only_line_comment_crlf.kdl"));
}

test "TestSuite HappyPath: only_line_comment_newline." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/only_line_comment_newline.kdl"), @embedFile("./test_suite/expected_kdl/only_line_comment_newline.kdl"));
}

test "TestSuite FailPath: parens_in_bare_id." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteFailTestCase(allocator, @embedFile("./test_suite/input/parens_in_bare_id.kdl"));
}

test "TestSuite HappyPath: parse_all_arg_types." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/parse_all_arg_types.kdl"), @embedFile("./test_suite/expected_kdl/parse_all_arg_types.kdl"));
}

test "TestSuite HappyPath: positive_exponent." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/positive_exponent.kdl"), @embedFile("./test_suite/expected_kdl/positive_exponent.kdl"));
}

test "TestSuite HappyPath: positive_int." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/positive_int.kdl"), @embedFile("./test_suite/expected_kdl/positive_int.kdl"));
}

test "TestSuite HappyPath: preserve_duplicate_nodes." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/preserve_duplicate_nodes.kdl"), @embedFile("./test_suite/expected_kdl/preserve_duplicate_nodes.kdl"));
}

test "TestSuite HappyPath: preserve_node_order." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/preserve_node_order.kdl"), @embedFile("./test_suite/expected_kdl/preserve_node_order.kdl"));
}

test "TestSuite HappyPath: prop_false_type." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/prop_false_type.kdl"), @embedFile("./test_suite/expected_kdl/prop_false_type.kdl"));
}

test "TestSuite HappyPath: prop_float_type." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/prop_float_type.kdl"), @embedFile("./test_suite/expected_kdl/prop_float_type.kdl"));
}

test "TestSuite HappyPath: prop_hex_type." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/prop_hex_type.kdl"), @embedFile("./test_suite/expected_kdl/prop_hex_type.kdl"));
}

test "TestSuite HappyPath: prop_null_type." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/prop_null_type.kdl"), @embedFile("./test_suite/expected_kdl/prop_null_type.kdl"));
}

test "TestSuite HappyPath: prop_raw_string_type." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/prop_raw_string_type.kdl"), @embedFile("./test_suite/expected_kdl/prop_raw_string_type.kdl"));
}

test "TestSuite HappyPath: prop_string_type." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/prop_string_type.kdl"), @embedFile("./test_suite/expected_kdl/prop_string_type.kdl"));
}

test "TestSuite HappyPath: prop_true_type." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/prop_true_type.kdl"), @embedFile("./test_suite/expected_kdl/prop_true_type.kdl"));
}

test "TestSuite HappyPath: prop_type." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/prop_type.kdl"), @embedFile("./test_suite/expected_kdl/prop_type.kdl"));
}

test "TestSuite HappyPath: prop_zero_type." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/prop_zero_type.kdl"), @embedFile("./test_suite/expected_kdl/prop_zero_type.kdl"));
}

test "TestSuite FailPath: question_mark_at_start_of_int." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteFailTestCase(allocator, @embedFile("./test_suite/input/question_mark_at_start_of_int.kdl"));
}

test "TestSuite FailPath: question_mark_before_number." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteFailTestCase(allocator, @embedFile("./test_suite/input/question_mark_before_number.kdl"));
}

test "TestSuite HappyPath: quoted_arg_type." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/quoted_arg_type.kdl"), @embedFile("./test_suite/expected_kdl/quoted_arg_type.kdl"));
}

test "TestSuite HappyPath: quoted_node_name." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/quoted_node_name.kdl"), @embedFile("./test_suite/expected_kdl/quoted_node_name.kdl"));
}

test "TestSuite HappyPath: quoted_node_type." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/quoted_node_type.kdl"), @embedFile("./test_suite/expected_kdl/quoted_node_type.kdl"));
}

test "TestSuite HappyPath: quoted_numeric." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/quoted_numeric.kdl"), @embedFile("./test_suite/expected_kdl/quoted_numeric.kdl"));
}

test "TestSuite HappyPath: quoted_prop_name." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/quoted_prop_name.kdl"), @embedFile("./test_suite/expected_kdl/quoted_prop_name.kdl"));
}

test "TestSuite HappyPath: quoted_prop_type." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/quoted_prop_type.kdl"), @embedFile("./test_suite/expected_kdl/quoted_prop_type.kdl"));
}

test "TestSuite FailPath: quote_in_bare_id." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteFailTestCase(allocator, @embedFile("./test_suite/input/quote_in_bare_id.kdl"));
}

test "TestSuite HappyPath: raw_arg_type." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/raw_arg_type.kdl"), @embedFile("./test_suite/expected_kdl/raw_arg_type.kdl"));
}

test "TestSuite HappyPath: raw_node_name." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/raw_node_name.kdl"), @embedFile("./test_suite/expected_kdl/raw_node_name.kdl"));
}

test "TestSuite HappyPath: raw_node_type." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/raw_node_type.kdl"), @embedFile("./test_suite/expected_kdl/raw_node_type.kdl"));
}

test "TestSuite HappyPath: raw_prop_type." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/raw_prop_type.kdl"), @embedFile("./test_suite/expected_kdl/raw_prop_type.kdl"));
}

test "TestSuite HappyPath: raw_string_arg." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/raw_string_arg.kdl"), @embedFile("./test_suite/expected_kdl/raw_string_arg.kdl"));
}

test "TestSuite HappyPath: raw_string_backslash." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/raw_string_backslash.kdl"), @embedFile("./test_suite/expected_kdl/raw_string_backslash.kdl"));
}

test "TestSuite HappyPath: raw_string_hash_no_esc." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/raw_string_hash_no_esc.kdl"), @embedFile("./test_suite/expected_kdl/raw_string_hash_no_esc.kdl"));
}

test "TestSuite HappyPath: raw_string_just_backslash." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/raw_string_just_backslash.kdl"), @embedFile("./test_suite/expected_kdl/raw_string_just_backslash.kdl"));
}

test "TestSuite HappyPath: raw_string_just_quote." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/raw_string_just_quote.kdl"), @embedFile("./test_suite/expected_kdl/raw_string_just_quote.kdl"));
}

test "TestSuite HappyPath: raw_string_multiple_hash." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/raw_string_multiple_hash.kdl"), @embedFile("./test_suite/expected_kdl/raw_string_multiple_hash.kdl"));
}

test "TestSuite HappyPath: raw_string_newline." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/raw_string_newline.kdl"), @embedFile("./test_suite/expected_kdl/raw_string_newline.kdl"));
}

test "TestSuite HappyPath: raw_string_prop." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/raw_string_prop.kdl"), @embedFile("./test_suite/expected_kdl/raw_string_prop.kdl"));
}

test "TestSuite HappyPath: raw_string_quote." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/raw_string_quote.kdl"), @embedFile("./test_suite/expected_kdl/raw_string_quote.kdl"));
}

test "TestSuite HappyPath: repeated_arg." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/repeated_arg.kdl"), @embedFile("./test_suite/expected_kdl/repeated_arg.kdl"));
}

test "TestSuite HappyPath: repeated_prop." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/repeated_prop.kdl"), @embedFile("./test_suite/expected_kdl/repeated_prop.kdl"));
}

test "TestSuite HappyPath: r_node." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/r_node.kdl"), @embedFile("./test_suite/expected_kdl/r_node.kdl"));
}

test "TestSuite HappyPath: same_args." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/same_args.kdl"), @embedFile("./test_suite/expected_kdl/same_args.kdl"));
}

test "TestSuite HappyPath: same_name_nodes." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/same_name_nodes.kdl"), @embedFile("./test_suite/expected_kdl/same_name_nodes.kdl"));
}

test "TestSuite HappyPath: sci_notation_large." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/sci_notation_large.kdl"), @embedFile("./test_suite/expected_kdl/sci_notation_large.kdl"));
}

test "TestSuite HappyPath: sci_notation_small." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/sci_notation_small.kdl"), @embedFile("./test_suite/expected_kdl/sci_notation_small.kdl"));
}

test "TestSuite HappyPath: semicolon_after_child." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/semicolon_after_child.kdl"), @embedFile("./test_suite/expected_kdl/semicolon_after_child.kdl"));
}

test "TestSuite HappyPath: semicolon_in_child." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/semicolon_in_child.kdl"), @embedFile("./test_suite/expected_kdl/semicolon_in_child.kdl"));
}

test "TestSuite HappyPath: semicolon_separated." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/semicolon_separated.kdl"), @embedFile("./test_suite/expected_kdl/semicolon_separated.kdl"));
}

test "TestSuite HappyPath: semicolon_separated_nodes." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/semicolon_separated_nodes.kdl"), @embedFile("./test_suite/expected_kdl/semicolon_separated_nodes.kdl"));
}

test "TestSuite HappyPath: semicolon_terminated." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/semicolon_terminated.kdl"), @embedFile("./test_suite/expected_kdl/semicolon_terminated.kdl"));
}

test "TestSuite HappyPath: single_arg." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/single_arg.kdl"), @embedFile("./test_suite/expected_kdl/single_arg.kdl"));
}

test "TestSuite HappyPath: single_prop." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/single_prop.kdl"), @embedFile("./test_suite/expected_kdl/single_prop.kdl"));
}

test "TestSuite HappyPath: slashdash_arg_after_newline_esc." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/slashdash_arg_after_newline_esc.kdl"), @embedFile("./test_suite/expected_kdl/slashdash_arg_after_newline_esc.kdl"));
}

test "TestSuite HappyPath: slashdash_arg_before_newline_esc." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/slashdash_arg_before_newline_esc.kdl"), @embedFile("./test_suite/expected_kdl/slashdash_arg_before_newline_esc.kdl"));
}

test "TestSuite HappyPath: slashdash_child." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/slashdash_child.kdl"), @embedFile("./test_suite/expected_kdl/slashdash_child.kdl"));
}

test "TestSuite HappyPath: slashdash_empty_child." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/slashdash_empty_child.kdl"), @embedFile("./test_suite/expected_kdl/slashdash_empty_child.kdl"));
}

test "TestSuite HappyPath: slashdash_full_node." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/slashdash_full_node.kdl"), @embedFile("./test_suite/expected_kdl/slashdash_full_node.kdl"));
}

test "TestSuite HappyPath: slashdash_in_slashdash." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/slashdash_in_slashdash.kdl"), @embedFile("./test_suite/expected_kdl/slashdash_in_slashdash.kdl"));
}

test "TestSuite HappyPath: slashdash_negative_number." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/slashdash_negative_number.kdl"), @embedFile("./test_suite/expected_kdl/slashdash_negative_number.kdl"));
}

test "TestSuite HappyPath: slashdash_node_in_child." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/slashdash_node_in_child.kdl"), @embedFile("./test_suite/expected_kdl/slashdash_node_in_child.kdl"));
}

test "TestSuite HappyPath: slashdash_node_with_child." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/slashdash_node_with_child.kdl"), @embedFile("./test_suite/expected_kdl/slashdash_node_with_child.kdl"));
}

test "TestSuite HappyPath: slashdash_only_node." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/slashdash_only_node.kdl"), @embedFile("./test_suite/expected_kdl/slashdash_only_node.kdl"));
}

test "TestSuite HappyPath: slashdash_only_node_with_space." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/slashdash_only_node_with_space.kdl"), @embedFile("./test_suite/expected_kdl/slashdash_only_node_with_space.kdl"));
}

test "TestSuite HappyPath: slashdash_prop." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/slashdash_prop.kdl"), @embedFile("./test_suite/expected_kdl/slashdash_prop.kdl"));
}

test "TestSuite HappyPath: slashdash_raw_prop_key." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/slashdash_raw_prop_key.kdl"), @embedFile("./test_suite/expected_kdl/slashdash_raw_prop_key.kdl"));
}

test "TestSuite HappyPath: slashdash_repeated_prop." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/slashdash_repeated_prop.kdl"), @embedFile("./test_suite/expected_kdl/slashdash_repeated_prop.kdl"));
}

test "TestSuite FailPath: slash_in_bare_id." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteFailTestCase(allocator, @embedFile("./test_suite/input/slash_in_bare_id.kdl"));
}

test "TestSuite FailPath: space_after_arg_type." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteFailTestCase(allocator, @embedFile("./test_suite/input/space_after_arg_type.kdl"));
}

test "TestSuite FailPath: space_after_node_type." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteFailTestCase(allocator, @embedFile("./test_suite/input/space_after_node_type.kdl"));
}

test "TestSuite FailPath: space_after_prop_type." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteFailTestCase(allocator, @embedFile("./test_suite/input/space_after_prop_type.kdl"));
}

test "TestSuite FailPath: space_in_arg_type." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteFailTestCase(allocator, @embedFile("./test_suite/input/space_in_arg_type.kdl"));
}

test "TestSuite FailPath: space_in_node_type." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteFailTestCase(allocator, @embedFile("./test_suite/input/space_in_node_type.kdl"));
}

test "TestSuite FailPath: space_in_prop_type." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteFailTestCase(allocator, @embedFile("./test_suite/input/space_in_prop_type.kdl"));
}

test "TestSuite FailPath: square_bracket_in_bare_id." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteFailTestCase(allocator, @embedFile("./test_suite/input/square_bracket_in_bare_id.kdl"));
}

test "TestSuite HappyPath: string_arg." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/string_arg.kdl"), @embedFile("./test_suite/expected_kdl/string_arg.kdl"));
}

test "TestSuite HappyPath: string_prop." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/string_prop.kdl"), @embedFile("./test_suite/expected_kdl/string_prop.kdl"));
}

test "TestSuite HappyPath: tab_space." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/tab_space.kdl"), @embedFile("./test_suite/expected_kdl/tab_space.kdl"));
}

test "TestSuite HappyPath: trailing_crlf." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/trailing_crlf.kdl"), @embedFile("./test_suite/expected_kdl/trailing_crlf.kdl"));
}

test "TestSuite HappyPath: trailing_underscore_hex." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/trailing_underscore_hex.kdl"), @embedFile("./test_suite/expected_kdl/trailing_underscore_hex.kdl"));
}

test "TestSuite HappyPath: trailing_underscore_octal." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/trailing_underscore_octal.kdl"), @embedFile("./test_suite/expected_kdl/trailing_underscore_octal.kdl"));
}

test "TestSuite HappyPath: true_prefix_in_bare_id." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/true_prefix_in_bare_id.kdl"), @embedFile("./test_suite/expected_kdl/true_prefix_in_bare_id.kdl"));
}

test "TestSuite HappyPath: true_prefix_in_prop_key." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/true_prefix_in_prop_key.kdl"), @embedFile("./test_suite/expected_kdl/true_prefix_in_prop_key.kdl"));
}

test "TestSuite FailPath: true_prop_key." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteFailTestCase(allocator, @embedFile("./test_suite/input/true_prop_key.kdl"));
}

test "TestSuite HappyPath: two_nodes." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/two_nodes.kdl"), @embedFile("./test_suite/expected_kdl/two_nodes.kdl"));
}

test "TestSuite FailPath: type_before_prop_key." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteFailTestCase(allocator, @embedFile("./test_suite/input/type_before_prop_key.kdl"));
}

test "TestSuite FailPath: unbalanced_raw_hashes." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteFailTestCase(allocator, @embedFile("./test_suite/input/unbalanced_raw_hashes.kdl"));
}

test "TestSuite FailPath: underscore_at_start_of_fraction." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteFailTestCase(allocator, @embedFile("./test_suite/input/underscore_at_start_of_fraction.kdl"));
}

test "TestSuite FailPath: underscore_at_start_of_hex." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteFailTestCase(allocator, @embedFile("./test_suite/input/underscore_at_start_of_hex.kdl"));
}

test "TestSuite FailPath: underscore_at_start_of_int." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteFailTestCase(allocator, @embedFile("./test_suite/input/underscore_at_start_of_int.kdl"));
}

test "TestSuite FailPath: underscore_before_number." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteFailTestCase(allocator, @embedFile("./test_suite/input/underscore_before_number.kdl"));
}

test "TestSuite HappyPath: underscore_in_exponent." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/underscore_in_exponent.kdl"), @embedFile("./test_suite/expected_kdl/underscore_in_exponent.kdl"));
}

test "TestSuite HappyPath: underscore_in_float." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/underscore_in_float.kdl"), @embedFile("./test_suite/expected_kdl/underscore_in_float.kdl"));
}

test "TestSuite HappyPath: underscore_in_fraction." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/underscore_in_fraction.kdl"), @embedFile("./test_suite/expected_kdl/underscore_in_fraction.kdl"));
}

test "TestSuite HappyPath: underscore_in_int." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/underscore_in_int.kdl"), @embedFile("./test_suite/expected_kdl/underscore_in_int.kdl"));
}

test "TestSuite HappyPath: underscore_in_octal." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/underscore_in_octal.kdl"), @embedFile("./test_suite/expected_kdl/underscore_in_octal.kdl"));
}

test "TestSuite HappyPath: unusual_bare_id_chars_in_quoted_id." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/unusual_bare_id_chars_in_quoted_id.kdl"), @embedFile("./test_suite/expected_kdl/unusual_bare_id_chars_in_quoted_id.kdl"));
}

test "TestSuite HappyPath: unusual_chars_in_bare_id." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/unusual_chars_in_bare_id.kdl"), @embedFile("./test_suite/expected_kdl/unusual_chars_in_bare_id.kdl"));
}

test "TestSuite HappyPath: zero_arg." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/zero_arg.kdl"), @embedFile("./test_suite/expected_kdl/zero_arg.kdl"));
}

test "TestSuite HappyPath: zero_float." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/zero_float.kdl"), @embedFile("./test_suite/expected_kdl/zero_float.kdl"));
}

test "TestSuite HappyPath: zero_int." {
    const allocator = std.testing.allocator;
    try helpers.testSuiteHappyTestCase(allocator, @embedFile("./test_suite/input/zero_int.kdl"), @embedFile("./test_suite/expected_kdl/zero_int.kdl"));
}

