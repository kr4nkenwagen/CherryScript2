package parser

import "../syntax"
import "../token_list"
import "../types"

parse_post :: proc(
	tokens: ^types.token_list_t,
) -> (
	sntx: ^types.syntax_t,
	code: types.exit_codes,
) {
	sntx = syntax.create() or_return
	sntx.token = token_list.peek(tokens, 0) or_return
	token_list.advance(tokens) or_return
	sntx.value = expression(tokens) or_return
	curr_token := token_list.peek(tokens, 0) or_return
	return
}
