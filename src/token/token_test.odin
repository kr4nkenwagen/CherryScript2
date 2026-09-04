package token

import "core:testing"
import "../types"

@(test)
create_sets_fields :: proc(t: ^testing.T) {
	tok, code := create(nil, .PLUS, "+")
	testing.expectf(t, code == .OK, "create failed: %v", code)
	testing.expectf(t, tok != nil, "create should return a token")
	testing.expectf(t, tok.type == .PLUS, "type should be preserved")
	testing.expectf(t, tok.literal == "+", "literal should be preserved")
	testing.expectf(t, tok.column == 0, "column should default to 0 without src")
	testing.expectf(t, tok.line == 0, "line should default to 0 without src")
}

@(test)
create_computes_column_from_src :: proc(t: ^testing.T) {
	src := new(types.source_code_t)
	src.column = 5
	src.line = 3
	tok, _ := create(src, .VAR, "var")
	testing.expectf(t, tok.column == 2, "column should be src.column - len(literal), got %d", tok.column)
	testing.expectf(t, tok.line == 3, "line should be src.line, got %d", tok.line)
	free(src)
}

@(test)
create_nil_errors :: proc(t: ^testing.T) {
	tok, code := create(nil, types.token_type_t(nil), "x")
	testing.expectf(t, tok == nil, "create with nil type should return nil")
	testing.expectf(t, code == .OBJECT_IS_NIL_IN_TOKEN_CREATE, "create nil type wrong code: %v", code)
}

@(test)
generate_unknown_token_type :: proc(t: ^testing.T) {
	tok, code := generate_unknown_token()
	testing.expectf(t, code == .OK, "generate_unknown_token failed: %v", code)
	testing.expectf(t, tok != nil, "should return a token")
	testing.expectf(t, tok.type == .UNKNOWN_TOKEN, "type should be UNKNOWN_TOKEN")
}