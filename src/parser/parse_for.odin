package parser

import "../syntax"
import "../token_list"
import "../types"

parse_for :: proc(
	tokens: ^types.token_list_t,
	parent: ^types.program_t,
) -> (
	sntx: ^types.syntax_t,
	code: types.exit_codes,
) {
	curr_syntax := syntax.create() or_return
	curr_syntax.token = token_list.peek(tokens, 0) or_return
	adv := token_list.advance(tokens) or_return
	if adv.type != types.token_type_t.LEFT_PAREN do return nil, types.exit_codes.UNEXPECTED_SYNTAX
	token_list.advance(tokens) or_return
	curr_syntax.left = line(tokens, parent) or_return
	curr_syntax.value = line(tokens, parent) or_return
	curr_syntax.right = line(tokens, parent) or_return
	curr_tok := token_list.peek(tokens, 0) or_return
	for curr_tok.type != types.token_type_t.LEFT_BRACE {
		token_list.advance(tokens) or_return
		curr_tok = token_list.peek(tokens, 0) or_return
	}
	curr_syntax.branch = branch(tokens, parent) or_return
	curr_syntax.branch.type = types.program_type_t.LOOP
	return curr_syntax, types.exit_codes.OK
}
