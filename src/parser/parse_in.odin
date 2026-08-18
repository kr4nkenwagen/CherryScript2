package parser

import "../syntax"
import "../token_list"
import "../types"

parse_in :: proc(tokens: ^types.token_list_t) -> (sntx: ^types.syntax_t, code: types.exit_codes) {
	parent := syntax.create() or_return
	parent.token = token_list.peek(tokens, 0) or_return
	token_list.advance(tokens) or_return
	parent.value = expression(tokens) or_return
	return parent, .OK
}
