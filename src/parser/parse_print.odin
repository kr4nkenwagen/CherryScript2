package parser

import "../syntax"
import "../sys"
import "../token_list"
import "../types"

parse_print :: proc(tokens: ^types.token_list_t) -> (^types.syntax_t, types.exit_codes) {
	parent, parent_err := syntax.create()
	if sys.is_error(parent_err) {
		return nil, parent_err
	}
	parent.token, parent_err = token_list.peek(tokens, 0)
	if sys.is_error(parent_err) {
		return nil, parent_err
	}
	_, adv_err := token_list.advance(tokens)
	if sys.is_error(adv_err) {
		return nil, adv_err
	}
	parent.value, parent_err = expression(tokens)
	if sys.is_error(parent_err) {
		return nil, parent_err
	}
	return parent, .OK
}
