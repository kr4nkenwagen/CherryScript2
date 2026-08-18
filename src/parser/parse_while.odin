package parser

import "../syntax"
import "../token_list"
import "../types"

parse_while :: proc(
	tokens: ^types.token_list_t,
	parent: ^types.program_t,
) -> (
	sntx: ^types.syntax_t,
	code: types.exit_codes,
) {
	curr_syntax := syntax.create() or_return
	curr_syntax.token = token_list.peek(tokens, 0) or_return
	token_list.advance(tokens) or_return
	curr_syntax.value = expression(tokens) or_return
	curr_syntax.branch = branch(tokens, parent) or_return
	curr_syntax.branch.type = .LOOP
	return curr_syntax, .OK
}
