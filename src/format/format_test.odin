package format

import "core:testing"
import "core:strings"
import "../token"
import "../types"

mk_builder :: proc() -> (b: strings.Builder) {
	strings.builder_init(&b)
	return
}

@(test)
capture_comments_single_line :: proc(t: ^testing.T) {
	comments := capture_comments("a = 1 # comment\nb = 2")
	testing.expectf(t, len(comments) == 1, "should capture 1 comment, got %d", len(comments))
	testing.expectf(t, comments[0].text == "# comment", "text: %s", comments[0].text)
	testing.expectf(t, comments[0].line == 1, "line should be 1, got %d", comments[0].line)
	testing.expectf(t, comments[0].column == 7, "column should be 7, got %d", comments[0].column)
	delete(comments)
}

@(test)
capture_comments_multiple :: proc(t: ^testing.T) {
	comments := capture_comments("# one\n# two")
	testing.expectf(t, len(comments) == 2, "should capture 2 comments, got %d", len(comments))
	testing.expectf(t, comments[0].text == "# one", "first: %s", comments[0].text)
	testing.expectf(t, comments[1].text == "# two", "second: %s", comments[1].text)
	testing.expectf(t, comments[1].line == 2, "second line should be 2, got %d", comments[1].line)
	delete(comments)
}

@(test)
capture_comments_skips_inside_string :: proc(t: ^testing.T) {
	comments := capture_comments("\"# not a comment\"")
	testing.expectf(t, len(comments) == 0, "comment marker inside string should be skipped, got %d", len(comments))
	delete(comments)
}

@(test)
capture_comments_no_comments :: proc(t: ^testing.T) {
	comments := capture_comments("var x = 1")
	testing.expectf(t, len(comments) == 0, "no comments should yield empty, got %d", len(comments))
	delete(comments)
}

@(test)
skip_quoted_closed_returns_past_quote :: proc(t: ^testing.T) {
	end, col := skip_quoted("\"hi\" x", 0, 1, rune('"'))
	testing.expectf(t, end == 4, "end should be 4, got %d", end)
	testing.expectf(t, col == 5, "col should be 5, got %d", col)
}

@(test)
skip_quoted_newline_unclosed :: proc(t: ^testing.T) {
	end, _ := skip_quoted("\"a\nb", 0, 1, rune('"'))
	testing.expectf(t, end == 2, "should stop at newline, got %d", end)
}

@(test)
is_tight_before_variants :: proc(t: ^testing.T) {
	testing.expectf(t, is_tight_before(.RIGHT_PAREN), "RIGHT_PAREN is tight before")
	testing.expectf(t, is_tight_before(.COMMA), "COMMA is tight before")
	testing.expectf(t, is_tight_before(.DOT), "DOT is tight before")
	testing.expectf(t, is_tight_before(.LEFT_PAREN), "LEFT_PAREN is tight before")
	testing.expectf(t, !is_tight_before(.NUMBER), "INT is not tight before")
	testing.expectf(t, !is_tight_before(.PLUS), "PLUS is not tight before")
}

@(test)
is_tight_after_variants :: proc(t: ^testing.T) {
	testing.expectf(t, is_tight_after(.LEFT_PAREN), "LEFT_PAREN is tight after")
	testing.expectf(t, is_tight_after(.DOT), "DOT is tight after")
	testing.expectf(t, is_tight_after(.BANG), "BANG is tight after")
	testing.expectf(t, !is_tight_after(.NUMBER), "INT is not tight after")
}

@(test)
needs_space_keyword_paren :: proc(t: ^testing.T) {
	testing.expectf(t, needs_space(.IF, .LEFT_PAREN), "if ( needs space")
	testing.expectf(t, needs_space(.FOR, .LEFT_PAREN), "for ( needs space")
}

@(test)
needs_space_tight :: proc(t: ^testing.T) {
	testing.expectf(t, !needs_space(.NUMBER, .COMMA), "comma is tight before")
	testing.expectf(t, !needs_space(.DOT, .IDENTIFIER), "dot is tight after")
}

@(test)
needs_space_default :: proc(t: ^testing.T) {
	testing.expectf(t, needs_space(.NUMBER, .PLUS), "int + int needs space")

	testing.expectf(t, needs_space(.VAR, .IDENTIFIER), "var x needs space")
}

@(test)
escape_string_literal_escapes_special :: proc(t: ^testing.T) {
	b := mk_builder()
	escape_string_literal("a\"b", &b)
	testing.expectf(t, strings.to_string(b) == "a\\\"b", "got: %s", strings.to_string(b))

	b2 := mk_builder()
	escape_string_literal("a\nb", &b2)
	testing.expectf(t, strings.to_string(b2) == "a\\nb", "newline escape got: %s", strings.to_string(b2))

	b3 := mk_builder()
	escape_string_literal("a\\b", &b3)
	testing.expectf(t, strings.to_string(b3) == "a\\\\b", "backslash escape got: %s", strings.to_string(b3))
}

@(test)
write_token_literal_plain :: proc(t: ^testing.T) {
	tok, _ := token.create(nil, .VAR, "foo")
	b := mk_builder()
	write_token_literal(tok, &b)
	testing.expectf(t, strings.to_string(b) == "foo", "got: %s", strings.to_string(b))
}

@(test)
write_token_literal_string_wrapper_quotes :: proc(t: ^testing.T) {
	tok, _ := token.create(nil, .STRING_WRAPPER, "hello")
	b := mk_builder()
	write_token_literal(tok, &b)
	testing.expectf(t, strings.to_string(b) == "\"hello\"", "got: %s", strings.to_string(b))
}

@(test)
write_token_literal_string_wrapper_escapes :: proc(t: ^testing.T) {
	tok, _ := token.create(nil, .STRING_WRAPPER, "a\"b")
	b := mk_builder()
	write_token_literal(tok, &b)
	testing.expectf(t, strings.to_string(b) == "\"a\\\"b\"", "got: %s", strings.to_string(b))
}

@(test)
format_source_simple_assignment :: proc(t: ^testing.T) {
	out, code := format_source("var x = 1\n")
	testing.expectf(t, code == .OK, "format_source failed: %v", code)
	testing.expectf(t, out == "var x = 1\n", "got: %s", out)
}

@(test)
format_source_block :: proc(t: ^testing.T) {
	out, code := format_source("fn main() {\nprint(1)\n}\n")
	testing.expectf(t, code == .OK, "format_source failed: %v", code)
	testing.expectf(t, strings.contains(out, "{\n"), "block should have brace and newline")
	testing.expectf(t, strings.contains(out, "\n  print(1)\n"), "inner line should be indented")
}

@(test)
format_source_handles_comments :: proc(t: ^testing.T) {
	out, code := format_source("var x = 1 # note\n")
	testing.expectf(t, code == .OK, "format_source failed: %v", code)
	testing.expectf(t, strings.contains(out, "# note"), "comment should be preserved")
}