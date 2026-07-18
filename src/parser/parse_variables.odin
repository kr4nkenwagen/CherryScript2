package parser

import "../error"
import "../syntax"
import "../token"
import "../token_list"
import "../types"


variable_declaration :: proc(tokens: ^types.token_list_t) -> (^types.syntax_t, types.exit_codes) {
	if tokens == nil {
		return nil, types.exit_codes.OBJECT_IS_NIL
	}
	declaration, declaration_err := syntax.create()
	if error.is_error(declaration_err) {
		return nil, declaration_err
	}
	declaration.token = token_list.peek(tokens, 0)
	curr_token, curr_token_err := token_list.advance(tokens)
	if error.is_error(curr_token_err) {
		return nil, curr_token_err
	}
	prev_syntax := declaration
	for {
		if curr_token.type == types.token_type_t.COMMA {
			curr_token, curr_token_err = token_list.advance(tokens)
			if error.is_error(curr_token_err) {
				return nil, curr_token_err
			}
		}
		if curr_token.type != types.token_type_t.IDENTIFIER {
			return nil, types.exit_codes.UNEXPECTED_SYNTAX
		}
		curr_syntax, curr_syntax_err := syntax.create()
		if error.is_error(curr_syntax_err) {
			return nil, curr_syntax_err
		}
		curr_syntax.token = curr_token
		eq_token, eq_token_err := token_list.advance(tokens)
		if error.is_error(eq_token_err) {
			return nil, eq_token_err
		}
		if eq_token.type == types.token_type_t.EQUAL {
			_, adv_err := token_list.advance(tokens)
			if error.is_error(adv_err) {
				return nil, adv_err
			}
			curr_syntax.value, curr_syntax_err = expression(tokens)
			if error.is_error(curr_syntax_err) {
				return nil, curr_syntax_err
			}
		} else {
			if declaration.token.type == types.token_type_t.CONST {
				return nil, types.exit_codes.UNASSIGNED_CONST
			}
			curr_syntax.value, curr_syntax_err = syntax.create()
			if error.is_error(curr_syntax_err) {
				return nil, curr_syntax_err
			}
			curr_syntax.value.token, curr_syntax_err = token.create(
				nil,
				types.token_type_t.NIL,
				"null",
			)
			if error.is_error(curr_syntax_err) {
				return nil, curr_syntax_err
			}
		}
		curr_token, curr_token_err = token_list.peek(tokens, 0)
		if error.is_error(curr_token_err) {
			return nil, curr_token_err
		}
		prev_syntax.left = curr_syntax
		prev_syntax = curr_syntax
		if curr_token.type != types.token_type_t.COMMA {
			break
		}
	}
	return declaration, types.exit_codes.OK
}

variable_remove :: proc(tokens: ^types.token_list_t) -> (^types.syntax_t, types.exit_codes) {
	declaration, declaration_err := syntax.create()
	if error.is_error(declaration_err) {
		return nil, declaration_err
	}
	peek_err: types.exit_codes
	declaration.token, peek_err = token_list.peek(tokens, 0)
	if error.is_error(peek_err) {
		return nil, peek_err
	}
	curr_token, curr_token_err := token_list.advance(tokens)
	if error.is_error(curr_token_err) {
		return nil, curr_token_err
	}
	prev_syntax := declaration
	for {
		if curr_token.type == types.token_type_t.COMMA {
			curr_token, curr_token_err = token_list.advance(tokens)
			if error.is_error(curr_token_err) {
				return nil, curr_token_err
			}
		}
		if curr_token.type != types.token_type_t.IDENTIFIER {
			return nil, types.exit_codes.UNEXPECTED_SYNTAX
		}
		curr_syntax, curr_syntax_err := syntax.create()
		if error.is_error(curr_syntax_err) {
			return nil, curr_syntax_err
		}
		curr_syntax.token = curr_token
		prev_syntax.left = curr_syntax
		prev_syntax = curr_syntax
		curr_token, curr_token_err = token_list.advance(tokens)
		if error.is_error(curr_token_err) {
			return nil, curr_token_err
		}
		if curr_token.type != types.token_type_t.COMMA {
			break
		}
	}
	return declaration, types.exit_codes.OK
}

array_declaration :: proc(tokens: ^types.token_list_t) -> (^types.syntax_t, types.exit_codes) {
	declaration, err := syntax.create()
	if error.is_error(err) {
		return nil, err
	}
	declaration_err: types.exit_codes
	declaration.token, declaration_err = token_list.peek(tokens, 0)
	if error.is_error(declaration_err) {
		return nil, declaration_err
	}
	curr_token, curr_token_err := token_list.advance(tokens)
	if error.is_error(curr_token_err) {
		return nil, curr_token_err
	}
	prev_syntax := declaration
	for {
		if curr_token.type == types.token_type_t.COMMA {
			curr_token, curr_token_err = token_list.advance(tokens)
			if error.is_error(curr_token_err) {
				return nil, curr_token_err
			}
		}
		if !(curr_token.type == types.token_type_t.IDENTIFIER ||
			   curr_token.type == types.token_type_t.NUMBER ||
			   curr_token.type == types.token_type_t.STRING_WRAPPER) {
			return nil, types.exit_codes.UNEXPECTED_IDENTIFIER_OR_LITERAL
		}
		curr_syntax, curr_syntax_err := syntax.create()
		if error.is_error(curr_syntax_err) {
			return nil, curr_syntax_err
		}
		curr_syntax.token = curr_token
		prev_syntax.left = curr_syntax
		prev_syntax = curr_syntax
		curr_token, curr_token_err = token_list.advance(tokens)
		if error.is_error(curr_token_err) {
			return nil, curr_token_err
		}
		if curr_token.type != types.token_type_t.COMMA {
			break
		}
	}
	if curr_token.type != types.token_type_t.RIGHT_BRACKET {
		return nil, types.exit_codes.BRACKET_NOT_CLOSED
	}
	token_list.advance(tokens)
	return declaration, types.exit_codes.OK
}

identifier :: proc(tokens: ^types.token_list_t) -> (^types.syntax_t, types.exit_codes) {
	curr_syntax, _ := syntax.create()
	curr_syntax_err: types.exit_codes
	curr_syntax.token, curr_syntax_err = token_list.peek(tokens, 0)
	if error.is_error(curr_syntax_err) {
		return nil, curr_syntax_err
	}
	if curr_syntax.token.type != types.token_type_t.IDENTIFIER {
		return nil, types.exit_codes.EXPECTED_IDENTIFIER
	}
	_, adv_err := token_list.advance(tokens)
	if error.is_error(adv_err) {
		return nil, adv_err
	}
	curr_token, curr_token_err := token_list.peek(tokens, 0)
	if error.is_error(curr_token_err) {
		return nil, curr_token_err
	}
	if curr_token.type == types.token_type_t.LEFT_BRACKET {
		curr_syntax.right, curr_syntax_err = array_declaration(tokens)
		if error.is_error(curr_syntax_err) {
			return nil, curr_syntax_err
		}
	}
	if curr_token.type == types.token_type_t.LEFT_PAREN {
		curr_syntax.left, curr_syntax_err = passed_function_args(tokens)
		if error.is_error(curr_syntax_err) {
			return nil, curr_syntax_err
		}
	}
	return curr_syntax, types.exit_codes.OK
}
