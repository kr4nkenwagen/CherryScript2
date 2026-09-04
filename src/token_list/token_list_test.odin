package token_list

import "core:testing"
import "../token"
import "../types"

mk_tok :: proc(type: types.token_type_t, literal: string) -> ^types.token_t {
	t, _ := token.create(nil, type, literal)
	return t
}

@(test)
create_initializes :: proc(t: ^testing.T) {
	l, code := create()
	testing.expectf(t, code == .OK, "create failed: %v", code)
	testing.expectf(t, l != nil, "create should return a list")
	testing.expectf(t, l.length == 0, "length should start at 0")
	testing.expectf(t, l.pointer == 0, "pointer should start at 0")
	testing.expectf(t, len(l.list) == 0, "list should start empty")
	remove(l)
}

@(test)
add_appends_and_bumps_length :: proc(t: ^testing.T) {
	l, _ := create()
	tok := mk_tok(.PLUS, "+")
	code := add(l, tok)
	testing.expectf(t, code == .OK, "add failed: %v", code)
	testing.expectf(t, l.length == 1, "length should be 1, got %d", l.length)
	testing.expectf(t, len(l.list) == 1, "list should hold 1")
	testing.expectf(t, l.list[0] == tok, "list[0] should be the added token")
	remove(l)
}

@(test)
add_nil_list_errors :: proc(t: ^testing.T) {
	tok := mk_tok(.PLUS, "+")
	code := add(nil, tok)
	testing.expectf(t, code == .OBJECT_IS_NIL_IN_TOKEN_LIST_ADD, "add(nil, tok) wrong code: %v", code)
}

@(test)
advance_moves_pointer :: proc(t: ^testing.T) {
	l, _ := create()
	a := mk_tok(.VAR, "var")
	b := mk_tok(.PLUS, "+")
	add(l, a)
	add(l, b)
	first, code := advance(l)
	testing.expectf(t, code == .OK, "advance #1 failed: %v", code)
	testing.expectf(t, first == b, "advance #1 should return the token at pointer+1 (b)")
	testing.expectf(t, l.pointer == 1, "pointer should be 1, got %d", l.pointer)
	second, code2 := advance(l)
	testing.expectf(t, second == nil, "advance #2 should run out")
	testing.expectf(t, code2 == .RAN_OUT_OF_TOKENS_IN_TOKEN_LIST_ADVANCE, "advance #2 wrong code: %v", code2)
	remove(l)
}

@(test)
advance_runs_out_at_end :: proc(t: ^testing.T) {
	l, _ := create()
	add(l, mk_tok(.VAR, "var"))
	advance(l)
	tkn, code := advance(l)
	testing.expectf(t, tkn == nil, "advance past end should return nil")
	testing.expectf(t, code == .RAN_OUT_OF_TOKENS_IN_TOKEN_LIST_ADVANCE, "advance past end wrong code: %v", code)
	remove(l)
}

@(test)
advance_nil_list_returns_unknown :: proc(t: ^testing.T) {
	tkn, code := advance(nil)
	testing.expectf(t, tkn != nil, "advance(nil) should return a token")
	testing.expectf(t, tkn.type == .UNKNOWN_TOKEN, "advance(nil) should return UNKNOWN_TOKEN")
	testing.expectf(t, code == .OK, "advance(nil) should have OK code, got %v", code)
}

@(test)
peek_returns_token_at_distance :: proc(t: ^testing.T) {
	l, _ := create()
	a := mk_tok(.VAR, "var")
	b := mk_tok(.PLUS, "+")
	add(l, a)
	add(l, b)
	tkn, code := peek(l, 0)
	testing.expectf(t, code == .OK, "peek failed: %v", code)
	testing.expectf(t, tkn == a, "peek(0) should return a")
	tkn, _ = peek(l, 1)
	testing.expectf(t, tkn == b, "peek(1) should return b")
	remove(l)
}

@(test)
peek_out_of_range_returns_unknown :: proc(t: ^testing.T) {
	l, _ := create()
	add(l, mk_tok(.VAR, "var"))
	tkn, _ := peek(l, 2)
	testing.expectf(t, tkn != nil, "peek out of range should return a token")
	testing.expectf(t, tkn.type == .UNKNOWN_TOKEN, "peek out of range should be UNKNOWN_TOKEN")
	remove(l)
}

@(test)
peek_nil_list_returns_unknown :: proc(t: ^testing.T) {
	tkn, _ := peek(nil, 0)
	testing.expectf(t, tkn != nil, "peek(nil) should return a token")
	testing.expectf(t, tkn.type == .UNKNOWN_TOKEN, "peek(nil) should be UNKNOWN_TOKEN")
}

@(test)
remove_frees_memory :: proc(t: ^testing.T) {
	l, _ := create()
	add(l, mk_tok(.VAR, "var"))
	code := remove(l)
	testing.expectf(t, code == .OK, "remove failed: %v", code)
}

@(test)
remove_nil_safe :: proc(t: ^testing.T) {
	code := remove(nil)
	testing.expectf(t, code == .OK, "remove(nil) should be OK, got %v", code)
}