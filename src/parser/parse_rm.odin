package parser

import "../syntax"
import "../sys"
import "../token_list"
import "../types"

parse_rm :: proc(tokens: ^types.token_list_t) -> (^types.syntax_t, types.exit_codes) {
	declaration, declaration_err := syntax.create()
	if sys.is_error(declaration_err) {
		return nil, declaration_err
	}
	peek_err: types.exit_codes
	declaration.token, peek_err = token_list.peek(tokens, 0)
	if sys.is_error(peek_err) {
		return nil, peek_err
	}
	curr_token, curr_token_err := token_list.advance(tokens)
	if sys.is_error(curr_token_err) {
		return nil, curr_token_err
	}
	prev_syntax := declaration
	for {
		if curr_token.type == .COMMA {
			curr_token, curr_token_err = token_list.advance(tokens)
			if sys.is_error(curr_token_err) {
				return nil, curr_token_err
			}
		}
		if curr_token.type != .IDENTIFIER {
			return nil, .UNEXPECTED_SYNTAX
		}
		curr_syntax, curr_syntax_err := syntax.create()
		if sys.is_error(curr_syntax_err) {
			return nil, curr_syntax_err
		}
		curr_syntax.token = curr_token
		prev_syntax.left = curr_syntax
		prev_syntax = curr_syntax
		curr_token, curr_token_err = token_list.advance(tokens)
		if sys.is_error(curr_token_err) {
			return nil, curr_token_err
		}
		if curr_token.type != .COMMA {
			break
		}
	}
	return declaration, .OK
}
