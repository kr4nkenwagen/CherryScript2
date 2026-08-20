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
	declaration := syntax.create() or_return
	declaration.token = token_list.peek(tokens, 0) or_return
	adv := token_list.advance(tokens) or_return
	declaration_err: types.exit_codes
	if adv.type == .CONST || adv.type == .VAR {
		declaration.value, declaration_err = variable_declaration(tokens)
		return declaration, declaration_err
	}
	if adv.type == .FUNCTION {
		declaration.value, declaration_err = parse_function(tokens, nil)
		return declaration, declaration_err
	}
	return nil, .UNEXPECTED_BEHAVIOUR_IN_PARSE_GLOBAL
}
