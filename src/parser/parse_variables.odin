package parser

import "../syntax"
import "../sys"
import "../token"
import "../token_list"
import "../types"


variable_declaration :: proc(tokens: ^types.token_list_t) -> (^types.syntax_t, types.exit_codes) {
	if tokens == nil {
		return nil, .OBJECT_IS_NIL
	}
	declaration, declaration_err := syntax.create()
	if sys.is_error(declaration_err) {
		return nil, declaration_err
	}
	declaration.token, declaration_err = token_list.peek(tokens, 0)
	if sys.is_error(declaration_err) {
		return nil, declaration_err
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
		eq_token, eq_token_err := token_list.advance(tokens)
		if sys.is_error(eq_token_err) {
			return nil, eq_token_err
		}
		if eq_token.type == .EQUAL {
			_, adv_err := token_list.advance(tokens)
			if sys.is_error(adv_err) {
				return nil, adv_err
			}
			curr_syntax.value, curr_syntax_err = expression(tokens)
			if sys.is_error(curr_syntax_err) {
				return nil, curr_syntax_err
			}
		} else {
			if declaration.token.type == .CONST {
				return nil, .UNASSIGNED_CONST
			}
			curr_syntax.value, curr_syntax_err = syntax.create()
			if sys.is_error(curr_syntax_err) {
				return nil, curr_syntax_err
			}
			curr_syntax.value.token, curr_syntax_err = token.create(nil, .NIL, "null")
			if sys.is_error(curr_syntax_err) {
				return nil, curr_syntax_err
			}
		}
		curr_token, curr_token_err = token_list.peek(tokens, 0)
		if sys.is_error(curr_token_err) {
			return nil, curr_token_err
		}
		prev_syntax.left = curr_syntax
		prev_syntax = curr_syntax
		if curr_token.type != .COMMA {
			break
		}
	}
	return declaration, .OK
}

variable_remove :: proc(tokens: ^types.token_list_t) -> (^types.syntax_t, types.exit_codes) {
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

array_declaration :: proc(tokens: ^types.token_list_t) -> (^types.syntax_t, types.exit_codes) {
	declaration, err := syntax.create()
	if sys.is_error(err) {
		return nil, err
	}
	declaration_err: types.exit_codes
	declaration.token, declaration_err = token_list.peek(tokens, 0)
	if sys.is_error(declaration_err) {
		return nil, declaration_err
	}
	curr_token, curr_token_err := token_list.advance(tokens)
	if sys.is_error(curr_token_err) {
		return nil, curr_token_err
	}
	prev_syntax: ^types.syntax_t = nil
	for {
		if curr_token.type == .COMMA {
			curr_token, curr_token_err = token_list.advance(tokens)
			if sys.is_error(curr_token_err) {
				return nil, curr_token_err
			}
		}
		curr_syntax, curr_syntax_err := expression(tokens)
		if sys.is_error(curr_syntax_err) {
			return nil, curr_syntax_err
		}
		if declaration.left == nil {
			declaration.left = curr_syntax
		} else {
			prev_syntax.right = curr_syntax
		}
		prev_syntax = curr_syntax
		curr_token, curr_token_err = token_list.peek(tokens, 0)
		if sys.is_error(curr_token_err) {
			return nil, curr_token_err
		}
		if curr_token.type != .COMMA {
			break
		}
	}
	if curr_token.type != .RIGHT_BRACKET {
		return nil, .BRACKET_NOT_CLOSED
	}
	_, curr_token_err = token_list.advance(tokens)
	if sys.is_error(curr_token_err) {
		return nil, curr_token_err
	}
	return declaration, .OK
}

identifier :: proc(tokens: ^types.token_list_t) -> (^types.syntax_t, types.exit_codes) {
	curr_syntax, curr_syntax_err := syntax.create()
	declaration := curr_syntax
	if sys.is_error(curr_syntax_err) {
		return nil, curr_syntax_err
	}
	curr_syntax.token, curr_syntax_err = token_list.peek(tokens, 0)
	if sys.is_error(curr_syntax_err) {
		return nil, curr_syntax_err
	}
	if curr_syntax.token.type != .IDENTIFIER {
		return nil, .EXPECTED_IDENTIFIER
	}
	_, adv_err := token_list.advance(tokens)
	if sys.is_error(adv_err) {
		return nil, adv_err
	}
	curr_token, curr_token_err := token_list.peek(tokens, 0)
	if sys.is_error(curr_token_err) {
		return nil, curr_token_err
	}
	for curr_token.type == .LEFT_BRACKET {
		if curr_syntax == nil {
			curr_syntax, curr_syntax_err = syntax.create()
			if sys.is_error(curr_syntax_err) {
				return nil, curr_syntax_err
			}
		}
		curr_token, curr_syntax_err = token_list.advance(tokens)
		if sys.is_error(curr_syntax_err) {
			return nil, curr_syntax_err
		}
		curr_syntax.value, curr_syntax_err = syntax.create()
		if sys.is_error(curr_syntax_err) {
			return nil, curr_syntax_err
		}
		curr_syntax.value.token = curr_token
		curr_token, curr_syntax_err = token_list.advance(tokens)
		if sys.is_error(curr_syntax_err) {
			return nil, curr_syntax_err
		}
		if curr_token.type != .RIGHT_BRACKET {
			return nil, .UNEXPECTED_SYNTAX
		}
		curr_token, curr_syntax_err = token_list.advance(tokens)
		if sys.is_error(curr_syntax_err) {
			return nil, curr_syntax_err
		}
		curr_syntax = curr_syntax.value
	}
	curr_syntax = declaration
	if curr_token.type == .LEFT_PAREN {
		curr_syntax.left, curr_syntax_err = passed_function_args(tokens)
		if sys.is_error(curr_syntax_err) {
			return nil, curr_syntax_err
		}
	}
	return curr_syntax, .OK
}
