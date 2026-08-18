package parser

import "../program"
import "../sys"
import "../token_list"
import "../types"

branch :: proc(
	tokens: ^types.token_list_t,
	parent: ^types.program_t,
) -> (
	prgm: ^types.program_t,
	code: types.exit_codes,
) {
	if tokens == nil do return nil, .OBJECT_IS_NIL
	curr_token := token_list.peek(tokens, 0) or_return
	for curr_token.type == types.token_type_t.TERMINATOR {
		token_list.advance(tokens) or_return
		curr_token = token_list.peek(tokens, 0) or_return
	}
	if curr_token.type != types.token_type_t.LEFT_BRACE do return nil, .BRACKET_NOT_OPENED
	token_list.advance(tokens) or_return
	prog := program.create(parent) or_return
	curr_token = token_list.peek(tokens, 0) or_return
	for curr_token.type != types.token_type_t.RIGHT_BRACE {
		if curr_token.type == types.token_type_t.END_OF_FILE do return nil, .UNEXPECTED_EOF
		synt: ^types.syntax_t = nil
		prev_synt: ^types.syntax_t = nil
		for curr_token.type != types.token_type_t.TERMINATOR &&
		    curr_token.type != types.token_type_t.RIGHT_BRACE {

			if curr_token.type == types.token_type_t.END_OF_FILE do return nil, .UNEXPECTED_EOF
			stmt := statement(tokens, prog) or_return
			if stmt != nil {
				if synt == nil do synt = stmt
				else do prev_synt.left = stmt
				prev_synt = stmt
			}
			curr_token = token_list.peek(tokens, 0) or_return
		}
		for curr_token.type == types.token_type_t.TERMINATOR {
			token_list.advance(tokens) or_return
			curr_token = token_list.peek(tokens, 0) or_return
		}
		if synt != nil {
			program.add(prog, synt) or_return
		}
	}
	token_list.advance(tokens) or_return
	return prog, .OK
}

line :: proc(
	tokens: ^types.token_list_t,
	parent: ^types.program_t,
) -> (
	sntx: ^types.syntax_t,
	code: types.exit_codes,
) {
	curr_syntax: ^types.syntax_t
	prev_syntax: ^types.syntax_t
	curr_token := token_list.peek(tokens, 0) or_return
	for curr_token.type != types.token_type_t.TERMINATOR &&
	    curr_token.type != types.token_type_t.RIGHT_PAREN {

		if curr_syntax == nil {
			curr_syntax = statement(tokens, parent) or_return
			prev_syntax = curr_syntax
			curr_token = token_list.peek(tokens, 0) or_return
			continue
		}
		curr_syntax_err: types.exit_codes
		curr_syntax = statement(tokens, parent) or_return
		if curr_syntax == nil {
			curr_token = token_list.peek(tokens, 0) or_return
			continue
		}
		curr_syntax.left = prev_syntax
		prev_syntax = curr_syntax
	}
	for curr_token.type == types.token_type_t.TERMINATOR {
		token_list.advance(tokens) or_return
		curr_token = token_list.peek(tokens, 0) or_return
	}
	return curr_syntax, .OK
}

run :: proc(
	tokens: ^types.token_list_t,
	parent: ^types.program_t,
) -> (
	prgm: ^types.program_t,
	code: types.exit_codes,
) {
	if tokens == nil do return nil, .OBJECT_IS_NIL
	prog := program.create(parent) or_return
	curr_token := token_list.peek(tokens, 0) or_return
	for curr_token != nil && curr_token.type != types.token_type_t.END_OF_FILE {
		for curr_token != nil &&
		    curr_token.type != .TERMINATOR &&
		    curr_token.type != .RIGHT_BRACE &&
		    curr_token.type != .LEFT_BRACE &&
		    curr_token.type != .RIGHT_PAREN {
			synt := statement(tokens, parent) or_return
			if synt != nil {
				program.add(prog, synt) or_return
			}
			curr_token = token_list.peek(tokens, 0) or_return
		}
		if curr_token != nil &&
		   (curr_token.type == .TERMINATOR ||
				   curr_token.type == .RIGHT_BRACE ||
				   curr_token.type == .LEFT_BRACE ||
				   curr_token.type == .RIGHT_PAREN) {
			_, adv_err := token_list.advance(tokens)
			if adv_err == .RAN_OUT_OF_TOKENS do break
			if sys.is_error(adv_err) do return nil, adv_err
		}
		curr_token = token_list.peek(tokens, 0) or_return
	}
	return prog, .OK
}
