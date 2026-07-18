package parser

import "../error"
import "../syntax"
import "../token_list"
import "../types"

primary_expression :: proc(tokens: ^types.token_list_t) -> (^types.syntax_t, types.exit_codes) {
	if tokens == nil {
		return nil, types.exit_codes.OBJECT_IS_NIL
	}
	curr_token, curr_token_err := token_list.peek(tokens, 0)
	if error.is_error(curr_token_err) {
		return nil, curr_token_err
	}
	if curr_token == nil {
		return nil, types.exit_codes.OK
	}
	#partial switch (curr_token.type) {
	case .LEFT_BRACKET:
		return array_declaration(tokens)
	case .IDENTIFIER:
		return identifier(tokens)
	case .STRING_WRAPPER, .NUMBER, .FALSE, .TRUE, .NIL:
		synt, err := syntax.create()
		if error.is_error(err) {
			return nil, err
		}
		synt.token = curr_token
		_, adv_err := token_list.advance(tokens)
		if error.is_error(adv_err) {
			return nil, adv_err
		}
		return synt, types.exit_codes.OK

	case .LEFT_PAREN:
		_, adv_err := token_list.advance(tokens)
		if error.is_error(adv_err) {
			return nil, adv_err
		}
		synt, err := expression(tokens)
		if error.is_error(err) {
			return nil, err
		}
		next_token, next_token_err := token_list.peek(tokens, 0)
		if error.is_error(next_token_err) {
			return nil, next_token_err
		}
		if next_token.type != .RIGHT_PAREN {
			return nil, types.exit_codes.UNCLOSED_PARENTHESIS
		}
		_, adv_err = token_list.advance(tokens)
		if error.is_error(adv_err) {
			return nil, adv_err
		}
		return synt, types.exit_codes.OK

	case:
		return nil, types.exit_codes.UNEXPECTED_BEHAVIOUR
	}
}

string_operations :: proc(tokens: ^types.token_list_t) -> (^types.syntax_t, types.exit_codes) {
	left, err := primary_expression(tokens)
	if error.is_error(err) {
		return nil, err
	}
	curr_token, curr_token_err := token_list.peek(tokens, 0)
	if error.is_error(curr_token_err) {
		return nil, curr_token_err
	}
	for curr_token.type == .COLON || curr_token.type == .COLON_HAT {
		op, alloc_err := syntax.create()
		if error.is_error(alloc_err) {
			return nil, alloc_err
		}
		op.token = curr_token
		op.left = left
		_, adv_err := token_list.advance(tokens)
		if error.is_error(adv_err) {
			return nil, adv_err
		}
		op.right, err = primary_expression(tokens)
		if error.is_error(err) {
			free(op)
			return nil, err
		}
		left = op
		curr_token, curr_token_err = token_list.peek(tokens, 0)
		if error.is_error(curr_token_err) {
			return nil, curr_token_err
		}
	}
	return left, types.exit_codes.OK
}

unary :: proc(tokens: ^types.token_list_t) -> (^types.syntax_t, types.exit_codes) {
	curr_token, curr_token_err := token_list.peek(tokens, 0)
	if error.is_error(curr_token_err) {
		return nil, curr_token_err
	}
	if curr_token.type == .BANG || curr_token.type == .MINUS {
		op, err := syntax.create()
		if error.is_error(err) {
			return nil, err
		}
		op.token = curr_token
		_, adv_err := token_list.advance(tokens)
		if error.is_error(adv_err) {
			return nil, adv_err
		}
		op.left, err = unary(tokens)
		if error.is_error(err) {
			free(op)
			return nil, err
		}
		return op, types.exit_codes.OK
	}
	return string_operations(tokens)
}

multiplicitive :: proc(tokens: ^types.token_list_t) -> (^types.syntax_t, types.exit_codes) {
	left, err := unary(tokens)
	if error.is_error(err) {
		return nil, err
	}
	curr_token, curr_token_err := token_list.peek(tokens, 0)
	if error.is_error(curr_token_err) {
		return nil, curr_token_err
	}
	for curr_token != nil &&
	    (curr_token.type == .STAR || curr_token.type == .SLASH || curr_token.type == .MODULUS) {
		op, alloc_err := syntax.create()
		if error.is_error(alloc_err) {
			return nil, alloc_err
		}
		op.token = curr_token
		op.left = left
		_, adv_err := token_list.advance(tokens)
		if error.is_error(adv_err) {
			return nil, adv_err
		}
		op.right, err = unary(tokens)
		if error.is_error(err) {
			free(op)
			return nil, err
		}
		left = op
		curr_token, curr_token_err = token_list.peek(tokens, 0)
		if error.is_error(curr_token_err) {
			return nil, curr_token_err
		}
	}
	return left, types.exit_codes.OK
}

additive :: proc(tokens: ^types.token_list_t) -> (^types.syntax_t, types.exit_codes) {
	left, err := multiplicitive(tokens)
	if error.is_error(err) {
		return nil, err
	}
	curr_token, curr_token_err := token_list.peek(tokens, 0)
	if error.is_error(curr_token_err) {
		return nil, curr_token_err
	}
	for curr_token != nil &&
	    (curr_token.type == .PLUS || curr_token.type == .MINUS || curr_token.type == .DOT_DOT) {
		op, alloc_err := syntax.create()
		if error.is_error(alloc_err) {
			return nil, alloc_err
		}
		op.token = curr_token
		op.left = left
		_, adv_err := token_list.advance(tokens)
		if error.is_error(adv_err) {
			return nil, adv_err
		}
		op.right, err = multiplicitive(tokens)
		if error.is_error(err) {
			free(op)
			return nil, err
		}
		left = op
		curr_token, curr_token_err = token_list.peek(tokens, 0)
		if error.is_error(curr_token_err) {
			return nil, curr_token_err
		}
	}
	return left, types.exit_codes.OK
}

comparision :: proc(tokens: ^types.token_list_t) -> (^types.syntax_t, types.exit_codes) {
	left, err := additive(tokens)
	if error.is_error(err) {
		return nil, err
	}
	curr_token, curr_token_err := token_list.peek(tokens, 0)
	if error.is_error(curr_token_err) {
		return nil, curr_token_err
	}
	for curr_token != nil &&
	    (curr_token.type == .GREATER_EQUAL ||
			    curr_token.type == .LESS_EQUAL ||
			    curr_token.type == .GREATER ||
			    curr_token.type == .LESS) {
		op, alloc_err := syntax.create()
		if error.is_error(alloc_err) {
			return nil, alloc_err
		}
		op.token = curr_token
		op.left = left
		_, adv_err := token_list.advance(tokens)
		if error.is_error(adv_err) {
			return nil, adv_err
		}
		op.right, err = additive(tokens)
		if error.is_error(err) {
			free(op)
			return nil, err
		}
		left = op
		curr_token, curr_token_err = token_list.peek(tokens, 0)
		if error.is_error(curr_token_err) {
			return nil, curr_token_err
		}
	}
	return left, types.exit_codes.OK
}

equality :: proc(tokens: ^types.token_list_t) -> (^types.syntax_t, types.exit_codes) {
	left, err := comparision(tokens)
	if error.is_error(err) {
		return nil, err
	}
	curr_token, curr_token_err := token_list.peek(tokens, 0)
	if error.is_error(curr_token_err) {
		return nil, curr_token_err
	}
	for curr_token != nil && (curr_token.type == .EQUAL_EQUAL || curr_token.type == .BANG_EQUAL) {
		op, alloc_err := syntax.create()
		if error.is_error(alloc_err) {
			return nil, alloc_err
		}
		op.token = curr_token
		op.left = left
		_, adv_err := token_list.advance(tokens)
		if error.is_error(adv_err) {
			return nil, adv_err
		}
		op.right, err = comparision(tokens)
		if error.is_error(err) {
			free(op)
			return nil, err
		}
		left = op
		curr_token, curr_token_err = token_list.peek(tokens, 0)
		if error.is_error(curr_token_err) {
			return nil, curr_token_err
		}
	}
	return left, types.exit_codes.OK
}

assignment :: proc(tokens: ^types.token_list_t) -> (^types.syntax_t, types.exit_codes) {
	left, err := equality(tokens)
	if error.is_error(err) {
		return nil, err
	}
	curr_token, curr_token_err := token_list.peek(tokens, 0)
	if error.is_error(curr_token_err) {
		return nil, curr_token_err
	}
	if curr_token != nil &&
	   (curr_token.type == .EQUAL ||
			   curr_token.type == .PLUS_EQUAL ||
			   curr_token.type == .MINUS_EQUAL ||
			   curr_token.type == .STAR_EQUAL ||
			   curr_token.type == .SLASH_EQUAL) {
		op, alloc_err := syntax.create()
		if error.is_error(alloc_err) {
			return nil, alloc_err
		}
		op.token = curr_token
		op.left = left
		_, adv_err := token_list.advance(tokens)
		if error.is_error(adv_err) {
			return nil, adv_err
		}
		op.right, err = assignment(tokens)
		if error.is_error(err) {
			free(op)
			return nil, err
		}
		return op, types.exit_codes.OK
	}
	return left, types.exit_codes.OK
}

expression :: proc(tokens: ^types.token_list_t) -> (^types.syntax_t, types.exit_codes) {
	return assignment(tokens)
}

statement :: proc(
	tokens: ^types.token_list_t,
	parent: ^types.program_t,
) -> (
	^types.syntax_t,
	types.exit_codes,
) {
	if tokens == nil {
		return nil, types.exit_codes.OBJECT_IS_NIL
	}
	curr_token, curr_token_err := token_list.peek(tokens, 0)
	if error.is_error(curr_token_err) {
		return nil, curr_token_err
	}
	#partial switch (curr_token.type) {
	case .FUNCTION:
		return function(tokens, parent)
	case .FOR:
		return for_statement(tokens, parent)
	case .IF:
		return if_statement(tokens, parent)
	case .PRINT:
		return function_print(tokens)
	case .RETURN:
		return return_statement(tokens)
	case .VAR, .CONST:
		return variable_declaration(tokens)
	case .WHILE:
		return while(tokens, parent)
	case .PRINT_LINE:
		return function_print_line(tokens)
	case .CONTINUE:
		return continue_statement(tokens)
	case .BREAK:
		return break_statement(tokens)
	case .OUT:
		return out(tokens)
	case .ERROR:
		return error(tokens)
	case .REMOVE:
		return variable_remove(tokens)
	case:
		return expression(tokens)
	}
}
