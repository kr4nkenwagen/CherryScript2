package parser

import "../syntax"
import "../token"
import "../token_list"
import "../types"


variable_declaration :: proc(
	tokens: ^types.token_list_t,
) -> (
	sntx: ^types.syntax_t,
	code: types.exit_codes,
) {
	if tokens == nil do return nil, .OBJECT_IS_NIL
	declaration := syntax.create() or_return
	declaration.token = token_list.peek(tokens, 0) or_return
	curr_token := token_list.advance(tokens) or_return
	prev_syntax := declaration
	for {
		if curr_token.type == .COMMA {
			curr_token = token_list.advance(tokens) or_return
		}
		if curr_token.type != .IDENTIFIER do return nil, .UNEXPECTED_SYNTAX
		curr_syntax := syntax.create() or_return
		curr_syntax.token = curr_token
		eq_token := token_list.advance(tokens) or_return
		if eq_token.type == .EQUAL {
			token_list.advance(tokens) or_return
			curr_syntax.value = expression(tokens) or_return
		} else {
			if declaration.token.type == .CONST do return nil, .UNASSIGNED_CONST
			curr_syntax.value = syntax.create() or_return
			curr_syntax.value.token = token.create(nil, .NULL, "null") or_return
		}
		curr_token = token_list.peek(tokens, 0) or_return
		prev_syntax.left = curr_syntax
		prev_syntax = curr_syntax
		if curr_token.type != .COMMA do break
	}
	return declaration, .OK
}

variable_remove :: proc(
	tokens: ^types.token_list_t,
) -> (
	sntx: ^types.syntax_t,
	code: types.exit_codes,
) {
	declaration := syntax.create() or_return
	peek_err: types.exit_codes
	declaration.token = token_list.peek(tokens, 0) or_return
	curr_token := token_list.advance(tokens) or_return
	prev_syntax := declaration
	for {
		if curr_token.type == .COMMA {
			curr_token = token_list.advance(tokens) or_return
		}
		if curr_token.type != .IDENTIFIER do return nil, .UNEXPECTED_SYNTAX
		curr_syntax := syntax.create() or_return
		curr_syntax.token = curr_token
		prev_syntax.left = curr_syntax
		prev_syntax = curr_syntax
		curr_token = token_list.advance(tokens) or_return
		if curr_token.type != .COMMA do break
	}
	return declaration, .OK
}

array_declaration :: proc(
	tokens: ^types.token_list_t,
) -> (
	sntx: ^types.syntax_t,
	code: types.exit_codes,
) {
	declaration := syntax.create() or_return
	declaration_err: types.exit_codes
	declaration.token = token_list.peek(tokens, 0) or_return
	curr_token := token_list.advance(tokens) or_return
	prev_syntax: ^types.syntax_t = nil
	for {
		for curr_token.type == .COMMA || curr_token.type == .TERMINATOR {
			curr_token = token_list.advance(tokens) or_return
		}
		curr_syntax := expression(tokens) or_return
		if declaration.left == nil do declaration.left = curr_syntax
		else do prev_syntax.right = curr_syntax
		prev_syntax = curr_syntax
		curr_token = token_list.peek(tokens, 0) or_return
		if curr_token.type != .COMMA && curr_token.type != .TERMINATOR do break
	}
	if curr_token.type != .RIGHT_BRACKET do return nil, .BRACKET_NOT_CLOSED
	token_list.advance(tokens) or_return
	return declaration, .OK
}
