package parser

import "../syntax"
import "../token_list"
import "../types"

parse_rm :: proc(tokens: ^types.token_list_t) -> (sntx: ^types.syntax_t, code: types.exit_codes) {
	sntx = syntax.create() or_return
	peek_err: types.exit_codes
	sntx.token = token_list.peek(tokens, 0) or_return
	curr_token := token_list.advance(tokens) or_return
	prev_syntax := sntx
	for {
		if curr_token.type == .COMMA {
			curr_token = token_list.advance(tokens) or_return
		}
		if curr_token.type != .IDENTIFIER do return nil, .EXPECTED_IDENTIFIER_IN_PARSE_RM
		curr_syntax := syntax.create() or_return
		curr_syntax.token = curr_token
		prev_syntax.left = curr_syntax
		prev_syntax = curr_syntax
		curr_token = token_list.advance(tokens) or_return
		if curr_token.type != .COMMA do break
	}
	return
}
