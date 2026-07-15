package parser

import "../syntax"
import "../token_list"
import "../types"

if_statement :: proc(
	tokens: ^types.token_list_t,
	parent: ^types.program_t,
) -> (
	^types.syntax_t,
	bool,
) {
	syntax_parent, _ := syntax.create()
	syntax_parent.token = token_list.peek(tokens, 0)
	token_list.advance(tokens)
	syntax_parent.value, _ = expression(tokens)
	for token_list.peek(tokens, 0).type == types.token_type_t.TERMINATOR {
		token_list.advance(tokens)
	}
	if token_list.peek(tokens, 0).type == types.token_type_t.LEFT_BRACE {
		//ERROR unexpected syntax
		return nil, true
	}
	syntax_parent.branch, _ = branch(tokens, parent)

}
