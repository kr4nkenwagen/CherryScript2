package parser

import "../syntax"
import "../sys"
import "../token_list"
import "../types"

parse_global :: proc(tokens: ^types.token_list_t) -> (^types.syntax_t, types.exit_codes) {
	declaration, declaration_err := syntax.create()
	if sys.is_error(declaration_err) {
		return nil, declaration_err
	}
	declaration.token, declaration_err = token_list.peek(tokens, 0)
	if sys.is_error(declaration_err) {
		return nil, declaration_err
	}
	adv, adv_err := token_list.advance(tokens)
	if sys.is_error(adv_err) {
		return nil, adv_err
	}
	if adv.type == .CONST || adv.type == .VAR {
		declaration.value, declaration_err = variable_declaration(tokens)
		return declaration, declaration_err
	}
	if adv.type == .FUNCTION {
		declaration.value, declaration_err = parse_function(tokens, nil)
		return declaration, declaration_err
	}
	return nil, .UNEXPECTED_BEHAVIOUR
}
