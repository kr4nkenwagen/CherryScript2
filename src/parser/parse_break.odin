package parser

import "../syntax"
import "../sys"
import "../token_list"
import "../types"

break_statement :: proc(tokens: ^types.token_list_t) -> (^types.syntax_t, types.exit_codes) {
	curr_syntax, curr_syntax_err := syntax.create()
	if sys.is_error(curr_syntax_err) {
		return nil, curr_syntax_err
	}
	curr_syntax.token, curr_syntax_err = token_list.peek(tokens, 0)
	if sys.is_error(curr_syntax_err) {
		return nil, curr_syntax_err
	}
	_, arg_err := token_list.advance(tokens)
	if sys.is_error(arg_err) {
		return nil, arg_err
	}
	return curr_syntax, types.exit_codes.OK
}


