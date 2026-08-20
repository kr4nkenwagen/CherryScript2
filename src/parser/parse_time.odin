package parser

import "../syntax"
import "../token_list"
import "../types"

parse_time :: proc(
	tokens: ^types.token_list_t,
) -> (
	sntx: ^types.syntax_t,
	code: types.exit_codes,
) {
	curr_syntax := syntax.create() or_return
	curr_syntax.token = token_list.peek(tokens, 0) or_return
	dot := token_list.advance(tokens) or_return
	if dot.type != .DOT do return nil, .EXPECTED_DOT_IN_PARSE_TIME
	ident := token_list.advance(tokens) or_return
	if ident.type != .IDENTIFIER do return nil, .EXPECTED_IDENTIFIER_IN_PARSE_TIME
	val := syntax.create() or_return
	val.token = ident
	curr_syntax.value = val
	adv := token_list.advance(tokens) or_return
	return curr_syntax, .OK
}
