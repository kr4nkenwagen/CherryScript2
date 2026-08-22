package parser

import "../syntax"
import "../token_list"
import "../types"

parse_global :: proc(
	tokens: ^types.token_list_t,
) -> (
	sntx: ^types.syntax_t,
	code: types.exit_codes,
) {
	sntx = syntax.create() or_return
	sntx.token = token_list.peek(tokens, 0) or_return
	adv := token_list.advance(tokens) or_return
	if adv.type == .CONST || adv.type == .VAR {
		sntx.value, code = variable_declaration(tokens)
		return
	}
	if adv.type == .FUNCTION {
		sntx.value, code = parse_function(tokens, nil)
		return
	}
	code = .UNEXPECTED_BEHAVIOUR_IN_PARSE_GLOBAL
	return
}
