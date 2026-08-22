package parser

import "../syntax"
import "../token_list"
import "../types"

parse_http :: proc(
	tokens: ^types.token_list_t,
) -> (
	sntx: ^types.syntax_t,
	code: types.exit_codes,
) {
	sntx = syntax.create() or_return
	sntx.token = token_list.peek(tokens, 0) or_return
	dot := token_list.advance(tokens) or_return
	if dot.type != .DOT do return nil, .EXPECTED_DOT_IN_PARSE_HTTP
	ident := token_list.advance(tokens) or_return
	if ident.type != .IDENTIFIER do return nil, .EXPECTED_IDENTIFIER_IN_PARSE_HTTP
	val := syntax.create() or_return
	val.token = ident
	sntx.value = val
	adv := token_list.advance(tokens) or_return
	sntx.value.value = expression(tokens) or_return
	curr_token := token_list.peek(tokens, 0) or_return
	return
}
