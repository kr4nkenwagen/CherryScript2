package parser

import "../syntax"
import "../sys"
import "../token_list"
import "../types"

time :: proc(tokens: ^types.token_list_t) -> (^types.syntax_t, types.exit_codes) {
	curr_syntax, curr_syntax_err := syntax.create()
	if sys.is_error(curr_syntax_err) {
		return nil, curr_syntax_err
	}
	curr_syntax.token, curr_syntax_err = token_list.peek(tokens, 0)
	if sys.is_error(curr_syntax_err) {
		return nil, curr_syntax_err
	}
	dot, dot_err := token_list.advance(tokens)
	if sys.is_error(dot_err) {
		return nil, dot_err
	}
	if dot.type != .DOT {
		return nil, .UNEXPECTED_CHARACTER
	}
	ident, ident_err := token_list.advance(tokens)
	if sys.is_error(ident_err) {
		return nil, ident_err
	}
	if ident.type != .IDENTIFIER {
		return nil, .UNEXPECTED_CHARACTER
	}
	val, val_err := syntax.create()
	if sys.is_error(val_err) {
		return nil, val_err
	}
	val.token = ident
	curr_syntax.value = val
	adv, adv_err := token_list.advance(tokens)
	if sys.is_error(adv_err) {
		return nil, adv_err
	}
	return curr_syntax, .OK
}
