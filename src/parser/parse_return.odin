package parser

import "../syntax"
import "../sys"
import "../token_list"
import "../types"

return_statement :: proc(tokens: ^types.token_list_t) -> (^types.syntax_t, types.exit_codes) {
	curr_syntax, curr_syntax_err := syntax.create()
	if sys.is_error(curr_syntax_err) {
		return nil, curr_syntax_err
	}
	curr_syntax.token, curr_syntax_err = token_list.peek(tokens, 0)
	if sys.is_error(curr_syntax_err) {
		return nil, curr_syntax_err
	}
	_, adv_err := token_list.advance(tokens)
	if sys.is_error(adv_err) {
		return nil, adv_err
	}
	curr_syntax.value, curr_syntax_err = expression(tokens)
	if sys.is_error(curr_syntax_err) {
		return nil, curr_syntax_err
	}
	return curr_syntax, types.exit_codes.OK
}
