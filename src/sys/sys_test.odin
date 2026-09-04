package sys

import "core:testing"
import "core:strings"
import "../token"
import "../types"

bytes_of :: proc(s: string) -> (b: []u8) {
	b = transmute([]u8)s
	return
}

@(test)
is_digit_classifies :: proc(t: ^testing.T) {
	testing.expectf(t, is_digit('0'), "'0' should be a digit")
	testing.expectf(t, is_digit('5'), "'5' should be a digit")
	testing.expectf(t, is_digit('9'), "'9' should be a digit")
	testing.expectf(t, !is_digit('a'), "'a' should not be a digit")
	testing.expectf(t, !is_digit(' '), "space should not be a digit")
}

@(test)
is_word_start_classifies :: proc(t: ^testing.T) {
	testing.expectf(t, is_word_start('a'), "lowercase should start a word")
	testing.expectf(t, is_word_start('Z'), "uppercase should start a word")
	testing.expectf(t, is_word_start('_'), "underscore should start a word")
	testing.expectf(t, !is_word_start('1'), "digit should not start a word")
	testing.expectf(t, !is_word_start('!'), "symbol should not start a word")
}

@(test)
is_end_of_word_classifies :: proc(t: ^testing.T) {
	testing.expectf(t, is_end_of_word(' '), "space ends a word")
	testing.expectf(t, is_end_of_word('\n'), "newline ends a word")
	testing.expectf(t, is_end_of_word(';'), "semicolon ends a word")
	testing.expectf(t, is_end_of_word('('), "paren ends a word")
	testing.expectf(t, !is_end_of_word('a'), "letter does not end a word")
	testing.expectf(t, !is_end_of_word('&'), "ampersand does not end a word")
}

@(test)
scan_string_closed :: proc(t: ^testing.T) {
	bytes := bytes_of("\"hello\"")
	end, closed := scan_string(bytes, 0)
	testing.expectf(t, closed, "should be closed")
	testing.expectf(t, end == 7, "end should be 7, got %d", end)
}

@(test)
scan_string_unterminated :: proc(t: ^testing.T) {
	bytes := bytes_of("\"hello")
	end, closed := scan_string(bytes, 0)
	testing.expectf(t, !closed, "should be unterminated")
	testing.expectf(t, end == len(bytes), "end should run to buffer end")
}

@(test)
scan_string_escape :: proc(t: ^testing.T) {
	bytes := bytes_of("\"a\\\"b\"")
	end, closed := scan_string(bytes, 0)
	testing.expectf(t, closed, "escaped quote should not close the string")
	testing.expectf(t, end == 6, "end should be 6, got %d", end)
}

@(test)
scan_comment_stops_at_newline :: proc(t: ^testing.T) {
	bytes := bytes_of("# note\nrest")
	end := scan_comment(bytes, 0)
	testing.expectf(t, end == 6, "comment should stop at newline, got %d", end)
	testing.expectf(t, bytes[end] == '\n', "should stop on newline")
}

@(test)
scan_comment_runs_to_end :: proc(t: ^testing.T) {
	bytes := bytes_of("# note")
	end := scan_comment(bytes, 0)
	testing.expectf(t, end == len(bytes), "comment should run to end of buffer")
}

@(test)
scan_number_integer :: proc(t: ^testing.T) {
	end := scan_number(bytes_of("123abc"), 0)
	testing.expectf(t, end == 3, "integer end should be 3, got %d", end)
}

@(test)
scan_number_negative :: proc(t: ^testing.T) {
	end := scan_number(bytes_of("-5x"), 0)
	testing.expectf(t, end == 2, "negative end should be 2, got %d", end)
}

@(test)
scan_number_decimal :: proc(t: ^testing.T) {
	end := scan_number(bytes_of("1.5y"), 0)
	testing.expectf(t, end == 3, "decimal end should be 3, got %d", end)
}

@(test)
scan_number_leading_dot :: proc(t: ^testing.T) {
	end := scan_number(bytes_of(".5"), 0)
	testing.expectf(t, end == 2, "leading-dot end should be 2, got %d", end)
}

@(test)
scan_number_range_not_decimal :: proc(t: ^testing.T) {
	end := scan_number(bytes_of("1..5"), 0)
	testing.expectf(t, end == 1, "range dots should not be a decimal, got %d", end)
}

@(test)
is_unary_minus_recognizes :: proc(t: ^testing.T) {
	testing.expectf(t, is_unary_minus(bytes_of("-5"), 0), "start of line minus is unary")
	testing.expectf(t, is_unary_minus(bytes_of(" -5"), 1), "minus after space is unary")
	testing.expectf(t, !is_unary_minus(bytes_of("a-5"), 1), "minus after operand is not unary")
}

@(test)
scan_word_stops_at_delimiter :: proc(t: ^testing.T) {
	end := scan_word(bytes_of("foo("), 0)
	testing.expectf(t, end == 3, "word end should be 3, got %d", end)
}

@(test)
is_keyword_matches :: proc(t: ^testing.T) {
	testing.expectf(t, is_keyword(bytes_of("if"), 0, "if"), "'if' should be a keyword")
	testing.expectf(t, is_keyword(bytes_of("IF"), 0, "IF"), "case-insensitive keyword match")
	testing.expectf(t, !is_keyword(bytes_of("xyz"), 0, "xyz"), "unrelated word should not match")
}

@(test)
is_keyword_rejects_suffix :: proc(t: ^testing.T) {
	testing.expectf(t, !is_keyword(bytes_of("aif"), 1, "if"), "letter before word disables keyword")
	testing.expectf(t, !is_keyword(bytes_of(".if"), 1, "if"), "dot before word disables keyword")
}

@(test)
paint_code_empty :: proc(t: ^testing.T) {
	testing.expectf(t, paint_code("") == "", "empty input should paint to empty string")
}

@(test)
paint_code_colors_keyword :: proc(t: ^testing.T) {
	result := paint_code("if")
	testing.expectf(t, strings.contains(result, CLR_TITLE), "keyword should be titled")
	testing.expectf(t, strings.contains(result, "if"), "keyword text should remain")
}

@(test)
paint_code_colors_string :: proc(t: ^testing.T) {
	result := paint_code("\"hi\"")
	testing.expectf(t, strings.contains(result, CLR_AMBER), "string should be amber")
	testing.expectf(t, strings.contains(result, "\"hi\""), "string text should remain")
}

@(test)
paint_code_colors_comment :: proc(t: ^testing.T) {
	result := paint_code("# note")
	testing.expectf(t, strings.contains(result, CLR_MUTED), "comment should be muted")
	testing.expectf(t, strings.contains(result, "note"), "comment text should remain")
}

@(test)
paint_code_colors_number :: proc(t: ^testing.T) {
	result := paint_code("42")
	testing.expectf(t, strings.contains(result, CLR_GREEN), "number should be green")
	testing.expectf(t, strings.contains(result, "42"), "number text should remain")
}

@(test)
parse_error_ok :: proc(t: ^testing.T) {
	testing.expectf(t, parse_error(.OK, nil) == "OK", "OK should map to 'OK'")
}

@(test)
parse_error_substitutes_token :: proc(t: ^testing.T) {
	tok, _ := token.create(nil, .IDENTIFIER, "foo")
	result := parse_error(.ERROR_READING_FILE_IN_FILE_GET, tok)
	testing.expectf(t, result == "Failed to read file 'foo'.", "got: %s", result)
}

@(test)
parse_error_nil_token_empties_placeholder :: proc(t: ^testing.T) {
	result := parse_error(.ERROR_READING_FILE_IN_FILE_GET, nil)
	testing.expectf(t, result == "Failed to read file ''.", "got: %s", result)
}

@(test)
is_error_ok_is_false :: proc(t: ^testing.T) {
	testing.expectf(t, !is_error(.OK), "OK should not be an error")
}

@(test)
is_error_non_ok_is_true :: proc(t: ^testing.T) {
	testing.expectf(t, is_error(.OBJECT_IS_NIL_IN_PROGRAM_ADD), "non-OK should be an error")
}

@(test)
get_correct_source_file_repl_fallback :: proc(t: ^testing.T) {
	src := new(types.source_code_t)
	sf := get_correct_source_file(0, src)
	testing.expectf(t, sf.name == "REPL", "empty sources should fall back to REPL")
	testing.expectf(t, sf.imported_at_index == 0, "REPL should be at index 0")
	free(src)
}

@(test)
get_correct_source_file_first_segment :: proc(t: ^testing.T) {
	src := new(types.source_code_t)
	append(&src.included_sources, types.source_file_t{name = "a.cherry", length = 10, imported_at_index = 0})
	append(&src.included_sources, types.source_file_t{name = "b.cherry", length = 10, imported_at_index = 10})
	sf := get_correct_source_file(3, src)
	testing.expectf(t, sf.name == "a.cherry", "line 3 should map to first file, got: %s", sf.name)
	free(src)
}